# Architecture

Incant is split into four layers: DSL metadata, runtime context, LiveView rendering, and policy/data execution.

## DSL metadata

`use Incant.Admin`, `use Incant.Resource`, `use Incant.Dashboard`, and `use Incant.Theme` compile declarative modules into metadata structs.

The metadata layer is intentionally inspectable:

- `Incant.Admin.Metadata`
- `Incant.Resource.Metadata`
- `Incant.Dashboard.Metadata`
- `Incant.Theme.Metadata`

The LiveView renderer consumes metadata; it does not depend on user-written HEEx templates for each resource.

## Live context

`Incant.Live.Context` is the runtime state passed to components. It includes:

- admin metadata
- visible resources and dashboards
- selected resource/dashboard
- actor and authorization result
- table state, rows, pagination
- selected row and form state
- typed and raw dashboard variables
- widget values

The context keeps component APIs small:

```heex
<Shell.view context={@context}>
  <Dashboard.view context={@context} />
  <Resource.view context={@context} />
</Shell.view>
```

## Renderer modules

The generic renderer is organized by surface:

- `Incant.Live.Shell`
- `Incant.Live.Dashboard`
- `Incant.Live.Resource`
- `Incant.Live.Resource.Header`
- `Incant.Live.Resource.Form`
- `Incant.Live.Resource.Detail`
- `Incant.Live.Resource.Table`

`Incant.Live.Resource` is mostly orchestration; table/detail/form concerns live in submodules.

## Data loading flow

`Incant.Live.AdminLive.handle_params/3` builds a base context, authorizes the admin surface, then loads data only when allowed.

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
