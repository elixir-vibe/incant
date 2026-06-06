# Architecture

Incant is split into five layers: DSL metadata, runtime context, semantic UI documents, UI adapters, and policy/data execution.

## DSL metadata

`use Incant.Admin`, `use Incant.Resource`, `use Incant.Dashboard`, and `use Incant.Theme` compile declarative modules into metadata structs.

The metadata layer is intentionally inspectable:

- `Incant.Admin.Metadata`
- `Incant.Resource.Metadata`
- `Incant.Dashboard.Metadata`
- `Incant.Theme.Metadata`

The runtime consumes metadata; it does not depend on user-written HEEx templates for each resource.

## Live context

The live context is the runtime state passed to components. It includes:

- admin metadata
- visible resources and dashboards
- selected resource/dashboard
- actor and authorization result
- table state, rows, pagination
- selected row and form state
- typed and raw dashboard variables
- widget values

The live context is converted into an `Incant.UI.Document`, which is the stable input for UI adapters.

## Semantic UI layer

`Incant.UI.Document.from_context/2` builds admin-domain UI nodes:

- `Incant.UI.Surfaces.*` for page-level surfaces
- `Incant.UI.Regions.*` for admin page sections
- `Incant.UI.Controls.*` for value-changing controls
- `Incant.UI.Actions.*` for user-triggered commands

This is not a generic component framework. Incant describes what the user can do; adapters decide markup, focus behavior, keyboard behavior, ARIA details, and local client state.

## UI adapters

The default adapter is `Incant.UI.Adapters.LiveView`. Configure adapters in runtime config:

```elixir
config :incant,
  ui_adapter: Incant.UI.Adapters.LiveView,
  density: :compact
```

Per-admin overrides use the admin module as the config key:

```elixir
config :incant, MyApp.Admin,
  ui_adapter: MyApp.Admin.UIAdapter,
  density: :compact
```

The admin DSL should define admin semantics. Visual preferences such as adapter and density belong in config unless they are intrinsic to the resource model.

## Data loading flow

The admin LiveView builds a base context, authorizes the admin surface, then loads data only when allowed.

For resources:

1. apply policy scope hooks
2. load rows from `data/1` or repo/schema query
3. apply search/filter/sort/pagination
4. load selected row and form state
5. authorize row/detail/form access

For dashboards:

1. cast dashboard variables
2. keep raw URL variables alongside typed values
3. execute widget query callbacks per widget
4. render widget errors locally instead of crashing the dashboard

## Authorization flow

Incant does not own authentication. It detects an actor from host LiveView assigns or uses configured extraction:

```elixir
use Incant.Admin,
  actor_assign: :current_scope,
  policy: MyApp.Admin.Policy
```

Policies are Bodyguard-compatible:

```elixir
def authorize(action, actor, context)
```

Optional scoping hooks protect list/detail data:

```elixir
def scope_query(actor, resource, queryable, context)
def scope_rows(actor, resource, rows, context)
```

Local resource/dashboard policies can override the admin policy for a specific surface.

## Installer flow

`mix incant.install` is an Igniter task. It creates starter files and patches Phoenix router/CSS when possible. Router patching uses AST checks and AST insertion with a conservative string fallback.
