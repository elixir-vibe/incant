# Architecture

Incant separates application-owned admin semantics from rendering and transport. A resource definition can run locally in a Phoenix application or be described as portable data and executed in its owning service over [SafeRPC](https://hexdocs.pm/safe_rpc).

## Layer map

```text
Admin / Resource / Dashboard / Dataset DSL
                    │
                    ▼
             local metadata
       modules, repos, callbacks, policies
                    │
         ┌──────────┴──────────┐
         ▼                     ▼
  local Incant.Session   portable Admin.Contract
         │                     │
         │                Service.Client
         │                     │ SafeRPC / HTTP session API
         └──────────┬──────────┘
                    ▼
              Live context
       actor, table state, rows, forms,
       variables, widget values, actions
                    │
                    ▼
            Incant.UI.Document
       surfaces → regions → controls/actions
                    │
                    ▼
       Incant.UI.Adapters.LiveView
                    │
                    ▼
        HEEx + host CSS + browser behavior
```

## DSL metadata

`use Incant.Admin`, `use Incant.Resource`, `use Incant.Dashboard`, `use Incant.Dataset`, and `use Incant.Theme` compile declarative modules into inspectable metadata.

Local metadata may contain executable terms:

- resource and schema modules;
- Ecto repos and queryables;
- query, form, option, and action callbacks;
- policy modules;
- dashboard widget functions;
- data-source adapters.

This metadata stays in the application or service VM that owns it.

## Portable contracts

`Incant.Admin.describe/1` resolves local metadata into `Incant.Admin.Contract`. Contracts contain stable service, surface, field, filter, action, layout, and presentation data suitable for transport and inspection.

Contracts do not contain repos, schema modules, function captures, or arbitrary executable terms. Service and surface identifiers are normalized to string-safe public IDs.

A central host can therefore render navigation and controls before executing a data operation, while the owning service remains responsible for queries and side effects.

## Sessions

`Incant.Session` is the rendering boundary. Local and remote implementations expose equivalent operations for:

- listing surfaces;
- loading an index with table state;
- reading one row;
- preparing and submitting forms;
- running row, bulk, and page actions;
- loading dashboard and dataset data.

`Incant.Service.Session` wraps a discovered remote entry. The LiveView renderer consumes the session protocol rather than branching on local versus remote transport.

## Live context

The LiveView builds runtime context containing:

- admin contract/metadata and selected surface;
- actor and authorization context;
- table state, rows, pagination, and selected row;
- form fields, values, validation, and submission state;
- typed and raw dashboard variables;
- widget values and localized errors;
- action metadata and result state.

Data is loaded only after relevant authorization checks pass.

## Semantic UI documents

`Incant.UI.Document.from_context/2` turns runtime context into admin-domain nodes:

- `Incant.UI.Surfaces.*` — page-level resources, dashboards, and datasets;
- `Incant.UI.Regions.*` — tables, forms, inspectors, widget grids, and filter rails;
- `Incant.UI.Controls.*` — semantic value-changing inputs;
- `Incant.UI.Actions.*` — semantic user commands.

This is not a generic component library. Incant describes what the operator sees and can do; adapters own markup, focus, keyboard behavior, ARIA, and local browser state.

## LiveView adapter

`Incant.UI.Adapters.LiveView` is the default adapter. It renders semantic documents into function components and uses internal theme recipes for slot classes.

```elixir
config :incant,
  ui_adapter: Incant.UI.Adapters.LiveView,
  density: :compact
```

Per-admin overrides use the admin module as the configuration key.

The adapter does not own data access or authorization. It emits events, receives updated context/documents, and renders the result.

## Resource execution

For a conventional Ecto resource:

1. resolve the base schema query or `query/1` callback;
2. apply policy `scope_query/4`;
3. cast and apply declared filters;
4. apply search and allowlisted sorting;
5. count, clamp the requested page, and paginate;
6. redact sensitive fields and normalize rows;
7. authorize and load selected-row/detail/form state.

For an application-owned `index/1` or `index/2` callback, the callback may return a small row list or an authoritative `%Incant.Result{}`. In-memory policy scoping uses `scope_rows/4`.

Create/update form operations resolve local schema and changeset metadata before persistence. Those executable details never appear in a portable resource contract.

## Dashboard execution

Dashboard variables keep both raw URL values and typed values. Each widget query receives variables and context independently. A widget error is represented on that widget rather than crashing the whole dashboard.

Widget results are normalized to transport-safe values for remote sessions. Presentation formats and naming vocabulary are applied after transport at the semantic/adapter boundary.

## Authorization

Incant does not authenticate users. The host extracts an actor from LiveView assigns or a configured callback and applies policies at admin, surface, row, form, and action boundaries.

Policy scoping runs before count and pagination. A central host can pass context to a service, but service-local policy remains authoritative for remote execution.

## Transport

With `rpc: true`, an admin module declares explicit SafeRPC operations for describe, index, read, and action execution. A service-owned SafeRPC server hosts those operations on a protected local socket.

`Incant.Service.Registry` reads trusted binding data, discovers descriptors, loads contracts, and creates service entries. `RegistryServer` keeps the current snapshot and can refresh it after service replacement.

Standalone HTTP routes wrap the same service sessions. They expose semantic Incant operations, not arbitrary RPC.

## Installer

`mix incant.install` uses Igniter to create starter modules and patch the Phoenix router and Tailwind source. Structural router changes use AST-aware patching with conservative fallback instructions when a safe insertion point cannot be found.
