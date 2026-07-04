# Dashboards

Incant is experimental; dashboard widgets and variable contracts may still change before a first stable release.


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

    table :slow_requests, span: 4, query: &MyApp.Admin.Metrics.LLM.slow_requests/2 do
      column :timestamp, label: "Timestamp", format: :datetime
      column :provider, label: "Provider"
      column :duration_ms, label: "Duration", format: :number
      column :cost_usd, label: "Cost", format: :money
    end

    chart :cost_over_time, :line, span: 8 do
      dataset MyApp.Admin.Datasets.LLMUsage
      x :timestamp, bucket: :hour
      y :cost_usd
      series :provider
      drilldown :provider
    end
  end
end
```

Table widgets may declare columns in the `table ... do` block. Declared columns control ordering and presentation metadata such as labels and formats. Incant does not infer domain-specific labels or formats from column names; use column metadata when presentation matters.

Dashboard query callbacks receive typed variable values as the first argument. For two-argument callbacks, the second argument includes both typed and raw URL values:

```elixir
def total_requests(variables, %{raw_variables: raw_variables}) do
  # variables may contain typed dates; raw_variables keeps original URL params.
end
```

See [Architecture](architecture.md) for the dashboard data-loading flow.
