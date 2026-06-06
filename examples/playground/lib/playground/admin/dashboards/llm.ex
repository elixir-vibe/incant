defmodule Playground.Admin.Dashboards.LLM do
  @moduledoc false

  use Incant.Dashboard

  alias Playground.LLM

  title("LLM Operations")

  variables do
    var(:range, :date_range, default: %{"from" => "2026-05-01", "to" => "2026-05-31"})
    var(:provider, :multi_select, options: [:openai, :anthropic, :google])
    var(:model, :select, options: ["gpt-4.1", "claude-sonnet-4", "gemini-3-pro"])
  end

  grid columns: 12, row_height: 8 do
    stat(:total_requests, span: 3, query: &LLM.total_requests/2)
    stat(:total_cost, span: 3, query: &LLM.total_cost/2, format: :currency)
    stat(:avg_latency, span: 3, query: &LLM.avg_latency/2)
    stat(:error_rate, span: 3, query: &LLM.error_rate/2, format: :percent)
    timeseries(:requests_over_time, span: 8, query: &LLM.requests_over_time/2)
    table(:slow_requests, span: 4, query: &LLM.slow_requests/2)
  end
end
