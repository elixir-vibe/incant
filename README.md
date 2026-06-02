# Incant

Incant is an Elixir/Phoenix-native control plane for serious admin, content, analytics, dashboards, and operations work.

It is currently in its first implementation pass. The initial package provides compile-time DSLs that produce inspectable metadata for resources, dashboards, themes, admin roots, and data sources. LiveView rendering, Ecto execution, Igniter generators, and CMS features will build on this metadata layer.

See [PLAN.md](PLAN.md) for the full product thesis and roadmap. See [CONVENTIONS.md](CONVENTIONS.md) for the recommended application structure.

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

  table density: :compact do
    column :number, link: true
    column :customer, value: & &1.customer.email
    column :total, format: :money
    column :status, as: :badge

    filter :status, :select
    filter :inserted_at, :date_range
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

## Example theme

```elixir
defmodule MyApp.Admin.Themes.Default do
  use Incant.Theme

  css_vars_prefix "--incant"
  palette :zinc
  accent :violet
  density [:compact, :comfortable, :spacious]

  tokens do
    color :background, "var(--incant-background)"
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
