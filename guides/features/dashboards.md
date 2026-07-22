# Dashboards

Dashboards combine typed variables with stat, timeseries, table, and chart widgets. Application callbacks own metrics and queries; Incant handles controls, layout, formatting, and localized loading errors.

## Define a dashboard

```elixir
defmodule MyApp.Admin.Dashboards.LLMOperations do
  use Incant.Dashboard

  title "LLM Operations"

  variables do
    var :range, :date_range, default: {:last, 24, :hours}
    var :provider, :multi_select, options: [:openai, :anthropic, :google]
    var :model, :select, options: ["gpt-4.1", "claude-3-5-haiku-20241022"]
  end

  grid columns: 12, row_height: 8 do
    stat :total_requests,
      span: 3,
      label: "Requests",
      format: :compact_number,
      query: &MyApp.Admin.Metrics.LLM.total_requests/2

    stat :total_cost,
      span: 3,
      label: "Spend",
      format: :money,
      query: &MyApp.Admin.Metrics.LLM.total_cost/2

    stat :avg_latency,
      span: 3,
      label: "Avg latency",
      format: :duration_ms,
      query: &MyApp.Admin.Metrics.LLM.avg_latency/2

    timeseries :requests_over_time,
      span: 8,
      label: "Requests over time",
      query: &MyApp.Admin.Metrics.LLM.requests_over_time/2

    table :slow_requests,
      span: 4,
      label: "Slow & failed",
      query: &MyApp.Admin.Metrics.LLM.slow_requests/2 do
      column :provider, label: "Provider"
      column :model, label: "Model"
      column :latency_ms, label: "Latency", format: :duration_ms
      column :cost_usd, label: "Cost", format: :money
      column :status, label: "Status"
    end
  end
end
```

Register it on an admin root:

```elixir
dashboard MyApp.Admin.Dashboards.LLMOperations
```

## Variables

Variable controls persist in URL state. The LiveView casts submitted values before invoking widget callbacks.

Built-in dashboard controls include:

- `:date_range`
- `:select`
- `:multi_select`
- text-like controls supported by the semantic control layer

A two-argument query receives typed variables and context:

```elixir
def total_requests(variables, context) do
  range = variables[:range]
  providers = variables[:provider]
  actor = context[:actor]

  MyApp.Analytics.count_requests(range, providers, actor)
end
```

The context also retains raw URL values:

```elixir
def metric(variables, %{raw_variables: raw_variables}) do
  # variables contains cast values; raw_variables contains URL strings/maps.
end
```

Use typed values for application queries. Raw values are useful for diagnostics or custom controls, not as trusted query input.

## Stat widgets

Stat callbacks return one value. Apply explicit formats for numeric or temporal values:

```elixir
stat :tokens, format: :compact_number, query: &Metrics.tokens/2
stat :cost, format: :money, query: &Metrics.cost/2
stat :latency, format: :duration_ms, query: &Metrics.latency/2
```

## Timeseries widgets

The default LiveView adapter accepts labelled points:

```elixir
def requests_over_time(_variables, _context) do
  [
    %{label: "3h", value: 42},
    %{label: "2h", value: 58},
    %{label: "1h", value: 51},
    %{label: "now", value: 67}
  ]
end
```

Keep bucket and aggregation logic in metrics/data-source modules so the dashboard remains presentation metadata.

## Table widgets

Table queries return row maps. Declared columns control order, labels, numeric alignment, formatting, and full-value tooltips where supported.

```elixir
def slow_requests(_variables, _context) do
  [
    %{
      provider: :openai,
      model: "gpt-4.1",
      latency_ms: 2_940,
      cost_usd: 0.018,
      status: :error
    }
  ]
end
```

Portable dashboard values convert atoms to strings across remote service boundaries. Incant applies the admin naming vocabulary to known terms such as `openai` while leaving unknown identifiers and model names unchanged.

## Dataset-backed charts

Chart widgets can bind to a registered dataset:

```elixir
chart :cost_over_time, :line, span: 8 do
  dataset MyApp.Admin.Datasets.LLMUsage
  x :timestamp, bucket: :hour
  y :cost_usd
  series :provider
  drilldown :provider
end
```

The chart declaration describes semantic binding. The dataset's data-source adapter owns query execution and aggregation.

## Grid layout

`grid columns:` defines the desktop grid. Widget `span` values control width; the default adapter collapses the layout responsively on narrower screens.

Keep spans intentional:

- small stats usually use 3 or 4 columns in a 12-column grid;
- primary timeseries/charts usually use 8 or 12;
- companion tables usually use 4 or 6.

## Errors

Widget queries execute independently. A failed widget is represented as a localized widget error rather than crashing the entire dashboard. Log and monitor the underlying callback failure; do not return exception terms as display data.

See [Architecture](../internals/architecture.md) for the dashboard loading path and [Datasets](datasets.md) for analytical data sources.
