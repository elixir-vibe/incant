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
    stat(:total_requests, span: 3, label: "Requests", query: &LLM.total_requests/2)
    stat(:total_tokens, span: 3, label: "Tokens", format: :compact_number, query: &LLM.total_tokens/2)
    stat(:total_cost, span: 3, label: "Spend", format: :money, query: &LLM.total_cost/2)
    stat(:avg_latency, span: 3, label: "Avg latency", format: :duration_ms, query: &LLM.avg_latency/2)

    timeseries(:requests_over_time, span: 8, label: "Requests over time", query: &LLM.requests_over_time/2)

    table(:slow_requests, span: 4, label: "Slow & failed", query: &LLM.slow_requests/2) do
      column(:provider, label: "Provider")
      column(:model, label: "Model")
      column(:latency_ms, label: "Latency", format: :duration_ms)
      column(:cost_usd, label: "Cost", format: :money)
      column(:status, label: "Status")
    end
  end
end
