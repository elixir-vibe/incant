# Service admin interfaces

Incant's distributed admin model is service-owned.

Each service declares the admin surface it exposes in its own application namespace, using ordinary Incant DSL modules. A central admin/control-plane application should discover, render, and dispatch those surfaces; it should not own the service's resource/action definitions.

```elixir
defmodule Billing.Admin do
  use Incant.Admin,
    service: :billing,
    version: "1"

  resource Billing.Admin.Resources.Invoice
  dashboard Billing.Admin.Dashboards.Operations
  dataset Billing.Admin.Datasets.Revenue
end
```

This mirrors how Mix tasks live in project namespaces: the framework defines the behaviour and conventions, while applications define their own modules.

## Local authoring, portable description

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

SafeRPC should expose a small standard Incant operation set. The operations are transport verbs, not user-defined remote MFAs.

Initial operation shape:

```elixir
:incant_describe
:incant_resource_query
:incant_resource_get
:incant_resource_action
:incant_dataset_query
:incant_dashboard_widget
```

A service adapter can be configured with the service's admin module:

```elixir
defmodule Billing.AdminRPC do
  use Incant.SafeRPC.Service,
    admin: Billing.Admin
end
```

Internally, the adapter dispatches to Incant runtime functions:

```elixir
Incant.Admin.describe(Billing.Admin)
Incant.Admin.query_resource(Billing.Admin, "invoices", params, context)
Incant.Admin.run_action(Billing.Admin, "invoices", "refund", payload, context)
```

The central control plane calls standard SafeRPC operations, but the service controls what those operations mean by exposing its own `Billing.Admin` module.

## Design constraints

- Do not expose remote MFA over the wire.
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
- `Incant.SafeRPC.Service` — SafeRPC adapter for a configured admin module.
- `Incant.RemoteAdmin` or similar — central-side client/data source for remote admin surfaces.
