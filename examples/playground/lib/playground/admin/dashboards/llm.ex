defmodule Playground.Admin.Dashboards.LLM do
  @moduledoc false

  use Incant.Dashboard

  alias Playground.Admin.Metrics.LLM, as: Metrics

  title("LLM Proxy")

  variables do
    var(:range, :date_range, default: {:last, 24, :hours})
    var(:provider, :multi_select, options: [:openai, :anthropic, :google])
    var(:model, :select, source: :models)
  end

  grid columns: 12, row_height: 8 do
    stat(:total_requests, span: 3, query: &Metrics.total_requests/2)
    stat(:total_cost, span: 3, query: &Metrics.total_cost/2, format: :currency)
    stat(:avg_latency, span: 3, query: &Metrics.avg_latency/2)
    stat(:error_rate, span: 3, query: &Metrics.error_rate/2)
    timeseries(:requests_over_time, span: 8)
    table(:slow_requests, span: 4)
  end
end
