# Incant

Incant is an Elixir/Phoenix-native control plane for serious admin, content, analytics, dashboards, and operations work.

It is currently in its first implementation pass. The package provides compile-time DSLs that produce inspectable metadata for resources, dashboards, themes, admin roots, and data sources, plus a generic LiveView renderer for tables, details, forms, filters, dashboards, and row actions.

See [PLAN.md](PLAN.md) for the full product thesis and roadmap, [CONVENTIONS.md](CONVENTIONS.md) for the recommended application structure, and [REFERENCES.md](REFERENCES.md) for external packages and products informing the design.

## Playground

A Phoenix playground lives in [`examples/playground`](examples/playground). It uses the local Incant package and VibeKit, then defines sample resources, a dashboard, and a theme contract. Visit `/admin` to see the generic LiveView renderer.

```sh
cd examples/playground
mix setup
mix phx.server
```

## Install

Generate starter files in a Phoenix app:

```sh
mix incant.install
```

The task creates:

```text
lib/my_app/admin.ex
lib/my_app/admin/resources/sample.ex
lib/my_app/admin/themes/default.ex
```

Then add the router and CSS snippets printed by the task.

## Example resource

```elixir
defmodule MyApp.Admin.Resources.Order do
  use Incant.Resource,
    schema: MyApp.Orders.Order,
    repo: MyApp.Repo

  query &MyApp.Admin.Queries.orders_index/2
  data &MyApp.Admin.Data.orders/1

  table density: :compact do
    column :number, link: true
    column :customer, value: & &1.customer.email
    column :total, format: :money
    column :status, as: :badge

    filter :status, :select
    filter :inserted_at, :date_range

    transformer :sales_performance do
      query_transformer &MyApp.Admin.Filters.sales_performance/3
    end

    search &MyApp.Admin.Filters.order_search/3
  end
end
```

## Example dashboard

```elixir
defmodule MyApp.Admin.Dashboards.LLMStats do
  use Incant.Dashboard

  title "LLM Proxy"

  variables do
    var :range, :date_range, default: {:last, 24, :hours}
    var :provider, :multi_select, options: [:openai, :anthropic, :google]
  end

  grid columns: 12, row_height: 8 do
    stat :total_requests, span: 3, query: &MyApp.Admin.Metrics.LLM.total_requests/2
    stat :total_cost, span: 3, query: &MyApp.Admin.Metrics.LLM.total_cost/2
    timeseries :requests_over_time, span: 8
    table :slow_requests, span: 4
  end
end
```

## Design tokens

Incant renderers use semantic CSS variables instead of fixed Tailwind palette classes. Add the Incant source path to your Tailwind app and define the variables in your app CSS:

```css
@source "../deps/incant/lib";

:root {
  --incant-primary: var(--color-violet-600);
  --incant-bg: white;
  --incant-bg-elevated: white;
  --incant-bg-accented: var(--color-zinc-100);
  --incant-border: var(--color-zinc-200);
  --incant-text: var(--color-zinc-700);
  --incant-text-muted: var(--color-zinc-500);
  --incant-text-highlighted: var(--color-zinc-950);
}
```

See `Incant.Design.css_variables/0` and the playground's `assets/css/app.css` for the complete token set.

## Filters

Resource filters are rendered and applied through `Incant.Filter`, a behaviour-backed registry. Built-ins include `:text`, `:select`, `:multi_select`, `:date_range`, and `:boolean`. For Ecto schema-backed resources, built-in query filters cast submitted values through `Ecto.Type.cast/2`, so field types such as integers, decimals, dates, datetimes, booleans, and `Ecto.Enum` values bind as typed query params.

```elixir
filter :status, :select, options: [:draft, :published]
filter :inserted_at, :date_range
```

Override an individual filter with a module that implements `Incant.Filter`:

```elixir
filter :expensive, :boolean, filter: MyApp.Admin.Filters.ExpensiveProduct
```

```elixir
defmodule MyApp.Admin.Filters.ExpensiveProduct do
  @behaviour Incant.Filter

  use Phoenix.Component
  import Incant.Live.Components

  def control(filter, value, _assigns) do
    assigns = %{filter: filter, value: value}

    ~H"""
    <.select
      name={"table[filters][#{@filter.name}]"}
      value={@value}
      prompt="Price"
      options={[{"Expensive", "true"}, {"Cheap", "false"}]}
    />
    """
  end

  def match?(_filter, _row, value) when value in [nil, ""], do: true
  def match?(_filter, row, "true"), do: row.price_cents >= 10_000
  def match?(_filter, row, "false"), do: row.price_cents < 10_000

  def apply_query(_filter, queryable, _value, _context), do: queryable
end
```

`match?/3` is used for in-memory rows. `apply_query/4` is reserved for query-backed resources and custom data sources. To apply all submitted filter values to a queryable, use:

```elixir
Incant.Filter.apply_filters(resource.table.filters, queryable, params["filter"], context)
```

## Resource forms

Incant form metadata is changeset-first for Ecto resources. The form DSL describes admin presentation and ordering; schemas and changesets remain the source of truth for data and validation.

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource, schema: MyApp.Catalog.Product, repo: MyApp.Repo

  changeset &MyApp.Catalog.Product.changeset/2

  form do
    field :name
    field :status, :select, options: [:draft, :active, :archived]
    field :price, :number
  end
end
```

When no form fields are declared, `Incant.Forms.fields/1` can infer fields from Ecto-style `schema.__schema__/1`, excluding `:id`, `:inserted_at`, and `:updated_at`.

## Authorization

Incant reuses the host Phoenix application's existing authentication. It does not generate a user model. The LiveView context exposes an `actor`, detected from assigns in this order:

```elixir
:current_scope
:current_user
:current_admin
:actor
:user
```

Configure an explicit assign and policy on the admin root when needed:

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    policy: MyApp.Admin.Policy,
    actor_assign: :current_scope
end
```

Policies use a Bodyguard-compatible callback shape:

```elixir
defmodule MyApp.Admin.Policy do
  use Incant.Policy

  def authorize(:view_admin, actor, context), do: allow_admin?(actor, context)
  def authorize(:view_resource, actor, %{resource: resource}), do: can_view?(actor, resource)
  def authorize(:view_dashboard, actor, %{dashboard: dashboard}), do: can_view?(actor, dashboard)
  def authorize(:view_row, actor, %{resource: resource, selected_row: row}), do: can_view_row?(actor, resource, row)
  def authorize(:create, actor, %{resource: resource}), do: can_create?(actor, resource)
  def authorize(:edit, actor, %{resource: resource, row: row}), do: can_edit?(actor, resource, row)
  def authorize(:run_action, actor, %{action: action, row: row}), do: can_run?(actor, action, row)
end
```

Return `true`/`:ok` to allow or `false`/`:error`/`{:error, reason}` to deny. Without a configured policy, Incant allows all actions.

Policies may also scope data:

```elixir
def scope_query(actor, resource, queryable, context) do
  MyApp.Admin.Authorization.scope_query(actor, resource, queryable, context)
end

def scope_rows(actor, resource, rows, context) do
  Enum.filter(rows, &can_view_row?(actor, resource, &1))
end
```

To bridge Bodyguard, delegate from the Incant policy:

```elixir
def authorize(action, actor, context) do
  Bodyguard.permit(MyApp.Admin.Authz, action, actor, context)
end
```

Phoenix 1.8 `phx.gen.auth` apps should usually set `actor_assign: :current_scope` and write policies against the generated scope struct.

## Row actions

Resource tables can declare row actions. Actions render in the table and detail view; provide a callback to execute behaviour from the LiveView.

```elixir
table do
  column :name, link: true

  action :archive,
    label: "Archive",
    tone: :danger,
    confirm: true,
    callback: &MyApp.Admin.Actions.archive_product/2
end
```

Callbacks receive `%{action:, id:, row:, resource:}` and the LiveView assigns. Return `:ok`, a message string, `{:ok, message}`, or `{:error, message}`.

## Query-backed resources

If a resource does not define `data/1`, Incant can load rows from `repo` and `schema`:

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource, schema: MyApp.Catalog.Product, repo: MyApp.Repo

  query &__MODULE__.base_query/2

  table do
    column :name, link: true
    filter :status, :select, query: &__MODULE__.status_filter/3
  end

  def base_query(schema, _context), do: schema
  def status_filter(query, status, _context), do: query
end
```

Custom filter query callbacks run before `repo.all/1`. Built-in filters apply Ecto `where` clauses for query-backed resources and bind values cast through the schema field type.

## Example theme

```elixir
defmodule MyApp.Admin.Themes.Default do
  use Incant.Theme

  css_vars_prefix "--incant"
  palette :zinc
  accent :violet
  density [:compact, :comfortable, :spacious]

  tokens do
    color :background, "var(--incant-bg)"
    radius :md, "var(--incant-radius-md)"
    spacing :table_row_height, "var(--incant-table-row-height)"
    font :sans, "var(--incant-font-sans)"
  end

  table do
    sticky_header true
    row_height "var(--incant-table-row-height)"
    zebra true
  end

  charts do
    chart_palette [:blue, :violet, :emerald, :amber, :rose]
  end
end
```

## Live components

The generic renderer follows Phoenix-style module names. Root components expose `view/1` and nested resource modules keep local names concise:

```heex
<Shell.view context={@context}>
  <Dashboard.view context={@context} />
  <Resource.view context={@context} />
</Shell.view>
```

Resource rendering is split across `Incant.Live.Resource.Header`, `Incant.Live.Resource.Form`, `Incant.Live.Resource.Detail`, and `Incant.Live.Resource.Table`.

## Development

This project was bootstrapped with VibeKit.

```sh
mix deps.get
mix test
mix ci
```

## Package name

`incant` was checked as available on Hex.pm before project creation.
