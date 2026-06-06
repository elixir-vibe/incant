# Dashboards


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

Dashboard query callbacks receive typed variable values as the first argument. For two-argument callbacks, the second argument includes both typed and raw URL values:

```elixir
def total_requests(variables, %{raw_variables: raw_variables}) do
  # variables may contain typed dates; raw_variables keeps original URL params.
end
```
