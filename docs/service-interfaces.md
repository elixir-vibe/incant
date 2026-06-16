# Service admin interfaces

Incant's distributed admin model is service-owned.

Each service declares the admin surface it exposes in its own application namespace, using ordinary Incant DSL modules. A central Incant admin can discover, render, and dispatch those surfaces; it should not own the service's resource/action definitions.

```elixir
defmodule Billing.Admin do
  use Incant.Admin,
    service: :billing,
    version: "1",
    repo: Billing.Repo

  expose Billing.Invoices.Invoice
  expose Billing.Customers.Customer

  dashboard Billing.Admin.Dashboards.Operations
  dataset Billing.Admin.Datasets.Revenue
end
```

This mirrors how Mix tasks live in project namespaces: the framework defines the behaviour and conventions, while applications define their own modules.

`expose/2` is convention-first. By default, Incant infers a resource from the Ecto schema and configured repo. If the application defines a conventional resource module, Incant uses it automatically without changing the admin root:

```elixir
defmodule Billing.Admin.Resources.Invoice do
  use Incant.Resource,
    schema: Billing.Invoices.Invoice

  table do
    column :number, link: true
    column :status, as: :badge
    action :refund, confirm: true
  end
end
```

Resolution order:

1. explicit `resource MyResourceModule` entries;
2. conventional override modules for `expose Schema`, such as `Billing.Admin.Resources.Invoice`;
3. inferred Ecto resources from `Schema.__schema__/1`.

## Local authoring, portable description

Top-level admin concepts are normalized as surfaces. A surface is a common envelope around kind-specific metadata:

```elixir
%Incant.Surface{
  kind: :resource,
  id: "invoice",
  module: Billing.Admin.Resources.Invoice,
  title: "Invoices",
  spec: %Incant.Resource.Metadata{}
}
```

The envelope owns identity for routes, navigation, public contracts, and remote transports. The `spec` owns resource/dashboard/dataset-specific semantics.

The service-local module remains the source of truth:

```elixir
Incant.metadata(Billing.Admin)
Incant.Admin.describe(Billing.Admin)
```

`Incant.metadata/1` returns local BEAM metadata, which may include modules, function captures, repos, schemas, and callbacks.

`Incant.Admin.describe/1` should return a portable, transport-safe admin contract. That contract is the thing suitable for remote discovery, persistence, audits, UI preloading, and SafeRPC responses.

The important split is:

- local metadata may contain executable BEAM terms;
- public descriptions contain only stable data;
- service-local executors own callbacks, repos, policies, and side effects.

## SafeRPC transport

A service opts into SafeRPC by enabling RPC on its ordinary admin module:

```elixir
defmodule Billing.Admin do
  use Incant.Admin,
    service: :billing,
    version: "1",
    repo: Billing.Repo,
    rpc: true

  expose Billing.Invoices.Invoice
end
```

That module still implements the local `Incant.Service` behaviour:

```elixir
Billing.Admin.describe(context)
Billing.Admin.index("invoice", params, context)
Billing.Admin.read("invoice", id, context)
Billing.Admin.run_action("invoice", "refund", payload, context)
```

With `rpc: true`, those same service functions are exposed through SafeRPC as explicit module/function operations:

```elixir
{Billing.Admin, :describe}
{Billing.Admin, :index}
{Billing.Admin, :read}
{Billing.Admin, :run_action}
```

Central Incant admin code should not repeat those operation tuples directly. In a HostKit deployment it should load the runtime registry from the binding file path injected as `HOSTKIT_RPC_BINDINGS`:

```elixir
{:ok, registry} = Incant.Service.Registry.load()

for %Incant.Service.Entry{client: client, contract: contract} <- registry.entries do
  # render the contract and dispatch later user actions through the same client
end
```

Long-running admin applications can supervise a registry server instead:

```elixir
children = [
  {Incant.Service.RegistryServer, name: MyApp.IncantRegistry}
]

Supervisor.start_link(children, strategy: :one_for_one)

entries = Incant.Service.RegistryServer.list_entries(MyApp.IncantRegistry)
{:ok, registry} = Incant.Service.RegistryServer.refresh(MyApp.IncantRegistry)
```

A Phoenix app mounts local or service-backed Incant admin through the same router macro:

```elixir
incant "/admin", MyApp.Admin
incant "/admin", registry: MyApp.IncantRegistry
```

The macro owns the private Phoenix LiveView session shape. `Incant.Live.Admin` consumes a selected `Incant.Session` through the same protocol used for local admin modules; it does not branch on local vs remote transport.

The registry decodes the ETF binding term safely:

```elixir
bindings =
  path
  |> File.read!()
  |> :erlang.binary_to_term([:safe])
```

Then it calls `SafeRPC.describe/1`, selects modules exposing the Incant service shape, and loads each contract through `Incant.Service.describe/1`.

For lower-level callers, Incant can also discover service clients directly from decoded bindings:

```elixir
{:ok, clients} = Incant.Service.discover(bindings)
```

For a known binding/module pair, callers can construct a client explicitly:

```elixir
client = Incant.Service.client(binding, module: Billing.Admin)

Incant.Service.index(client, %Incant.Service.Index{surface_id: "invoice", params: %{page: 1}})
Incant.Service.read(client, %Incant.Service.Read{surface_id: "invoice", id: "123"})
Incant.Service.run_action(client, %Incant.Service.RunAction{
  surface_id: "invoice",
  action_id: "refund",
  payload: %{id: "123"}
})
```

UI code should usually wrap registry entries in `Incant.Service.Session` so rendering does not know about request structs:

```elixir
session = Incant.Service.Session.new(entry, context: %{actor: actor})

Incant.Service.Session.list_surfaces(session, kind: :resource)
Incant.Service.Session.index(session, "invoice", %{page: 1})
Incant.Service.Session.read(session, "invoice", "123")
Incant.Service.Session.run_action(session, "invoice", "refund", %{id: "123"})
```

SafeRPC moves request structs and responses. The service-local admin module still owns callbacks, repos, policies, and side effects.

## Design constraints

- Do not expose arbitrary remote MFA over the wire; only explicitly generated module/function operations are callable.
- Do not serialize local callbacks or repo/schema modules as the public contract.
- Keep action/resource identifiers stable and string-safe for URLs and RPC payloads.
- Keep authorization service-local; the central UI can pass actor/context claims, but the service decides.
- Treat the public description as inspectable data, not as executable code.
- Keep semantic UI separate from transport. SafeRPC moves contracts and operation requests; Incant adapters render semantic surfaces.

## Direction

The next Incant layer should introduce explicit modules for this boundary:

- `Incant.Admin.describe/1` — local metadata to portable contract.
- `Incant.Admin.Contract` — transport-safe admin contract struct/schema.
- `Incant.Admin.Executor` — service-local resource/dataset/action execution.
- `use Incant.Admin, rpc: true` — SafeRPC exposure for the admin module's standard service functions.
- `Incant.Service.Client` — central-side client handle for remote admin surfaces.
