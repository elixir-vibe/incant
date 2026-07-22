# Distributed Services

Incant's distributed model keeps admin behavior with the service that owns the data. A central host discovers portable contracts, renders them, and sends semantic operations back to the service over [SafeRPC](https://hexdocs.pm/safe_rpc).

```text
Billing service                    Central Incant host
---------------                    -------------------
Billing.Admin                      RegistryServer
Billing.Repo             ◀──────▶  Service.Client
Billing.Admin.Policy      SafeRPC  LiveView adapter
queries and actions                semantic HTTP API
```

The central host does not load `Billing.Repo`, schema modules, callbacks, or policy code.

## Service-owned surface

```elixir
defmodule Billing.Admin do
  use Incant.Admin,
    service: :billing,
    version: "1",
    repo: Billing.Repo,
    policy: Billing.Admin.Policy,
    rpc: true

  expose Billing.Invoices.Invoice
  expose Billing.Customers.Customer
  dashboard Billing.Admin.Dashboards.Operations
end
```

`expose/2` is convention-first. Given `Billing.Invoices.Invoice`, Incant resolves surfaces in this order:

1. an explicitly registered resource module;
2. a conventional override such as `Billing.Admin.Resources.Invoice`;
3. an inferred Ecto resource from the schema and admin repo.

## Local metadata and portable contracts

Local metadata can contain executable BEAM terms:

```elixir
Incant.metadata(Billing.Admin)
```

That result may include modules, repos, schemas, callbacks, and function captures. It stays inside the service VM.

A public description is transport-safe:

```elixir
Incant.Admin.describe(Billing.Admin)
```

The description normalizes resources, dashboards, datasets, controls, fields, actions, and presentation metadata into an `Incant.Admin.Contract`. IDs are stable strings suitable for URLs and RPC payloads.

## SafeRPC operations

With `rpc: true`, the admin module exposes explicit service operations:

```text
{Billing.Admin, :describe}
{Billing.Admin, :index}
{Billing.Admin, :read}
{Billing.Admin, :run_action}
```

Host the module with SafeRPC:

```elixir
defmodule Billing.AdminServer do
  use SafeRPC.Adapter.Server, service: Billing.Admin
end
```

```elixir
children = [
  {Billing.AdminServer,
   socket: "/run/billing/admin.sock",
   socket_mode: 0o660}
]
```

Only declared SafeRPC operations are callable. Incant does not expose arbitrary remote MFA.

## Registry discovery

A binding file maps service keys to local sockets and candidate modules:

```elixir
%{
  "billing" => %{
    "socket" => "/run/billing/admin.sock",
    "modules" => ["Elixir.Billing.Admin"]
  }
}
```

Load once:

```elixir
{:ok, registry} = Incant.Service.Registry.load()

for %Incant.Service.Entry{client: client, contract: contract} <- registry.entries do
  {client, contract.service, contract.surfaces}
end
```

Or supervise a refreshable registry:

```elixir
children = [
  {Incant.Service.RegistryServer, name: MyApp.IncantRegistry}
]

entries = Incant.Service.RegistryServer.list_entries(MyApp.IncantRegistry)
{:ok, registry} = Incant.Service.RegistryServer.refresh(MyApp.IncantRegistry)
```

The default loader reads the binding path from `HOSTKIT_RPC_BINDINGS`. `Incant.Service.Registry.load/1` accepts a different environment variable when deployment naming differs.

## Render local and remote surfaces

The router macro uses the same LiveView session boundary for local and remote admins:

```elixir
incant "/admin", MyApp.Admin
incant "/admin", registry: MyApp.IncantRegistry
```

`Incant.Live.Admin` talks to an `Incant.Session`; it does not branch on whether a surface is local or remote.

## Service sessions

Wrap a discovered entry in a session for rendering or lower-level application code:

```elixir
session = Incant.Service.Session.new(entry, context: %{actor: actor})

Incant.Service.Session.list_surfaces(session, kind: :resource)
Incant.Service.Session.index(session, "invoice", %{page: 1})
Incant.Service.Session.read(session, "invoice", "123")
Incant.Service.Session.run_action(session, "invoice", "refund", %{id: "123"})
```

The service session translates those calls into typed request structs and SafeRPC operations.

Lower-level callers can construct a client explicitly:

```elixir
client = Incant.Service.client(binding, module: Billing.Admin)

Incant.Service.index(client, %Incant.Service.Index{
  surface_id: "invoice",
  params: %{page: 1}
})
```

Prefer sessions in UI code so rendering stays independent of transport request structs.

## Query execution

Portable resource queries describe table state as data. The service receives search, filters, sorting, pagination, variables, and context, then executes against its local repo or callback.

For remote Ecto resources:

- the schema and repo stay service-local;
- filter values are cast in the service;
- policy query scoping runs before pagination;
- rows are redacted and normalized before transport;
- callbacks and function captures are never serialized.

## Action execution

Row, bulk, and page actions use one semantic operation:

```elixir
%Incant.Service.RunAction{
  surface_id: "invoice",
  action_id: "refund",
  payload: %{
    id: "123",
    selected_ids: nil,
    assigns: %{},
    input: %{}
  }
}
```

The service resolves the action, authorizes the actor/context, loads local rows when needed, invokes the handler, and converts the result into portable action-result data.

One-time secrets should use `Incant.ActionResult.Reveal`; the central adapter renders the reveal but the service owns generation and authorization.

## Authorization

Keep authorization service-local. A central host may pass actor or tenant context, but each service decides whether to trust and authorize it.

For strong identity boundaries, derive signed or authenticated claims at the service edge rather than trusting arbitrary maps from the browser. The central UI's operator authentication and the service policy solve different problems.

## Failure behavior

Registry and transport failures are explicit. A service with a missing socket, incompatible descriptor, invalid contract, or failed `describe` call is not silently treated as an empty service.

Long-running hosts can refresh the registry after service replacement. Stable service and surface IDs keep routes and navigation consistent across refreshes.

## Related guides

- [Standalone Mode](../introduction/standalone-mode.md)
- [Admin HTTP API](../reference/admin-http-api.cheatmd)
- [Architecture](../internals/architecture.md)
