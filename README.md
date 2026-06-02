# Incant

Incant is an Elixir/Phoenix-native control plane for serious admin, content, analytics, dashboards, and operations work.

It is currently in its first implementation pass. The initial package provides compile-time DSLs that produce inspectable metadata for resources, dashboards, themes, admin roots, and data sources. LiveView rendering, Ecto execution, Igniter generators, and CMS features will build on this metadata layer.

See [PLAN.md](PLAN.md) for the full product thesis and roadmap, [CONVENTIONS.md](CONVENTIONS.md) for the recommended application structure, and [REFERENCES.md](REFERENCES.md) for external packages and products informing the design.

## Playground

A Phoenix playground lives in [`examples/playground`](examples/playground). It uses the local Incant package and VibeKit, then defines sample resources, a dashboard, and a theme contract. Visit `/admin` to see the generic LiveView renderer.

```sh
cd examples/playground
mix setup
mix phx.server
```

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

Resource filters are rendered and applied through `Incant.Filter`, a behaviour-backed registry. Built-ins include `:text`, `:select`, `:multi_select`, `:date_range`, and `:boolean`.

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
  import Incant.Live.UI

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

`match?/3` is used for in-memory rows. `apply_query/4` is reserved for query-backed resources and custom data sources.

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

## Development

This project was bootstrapped with VibeKit.

```sh
mix deps.get
mix test
mix ci
```

## Package name

`incant` was checked as available on Hex.pm before project creation.
