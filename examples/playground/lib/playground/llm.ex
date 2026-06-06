defmodule Playground.LLM do
  @moduledoc false

  alias Playground.LLM.Request

  def list_requests(_params \\ %{}) do
    [
      %Request{
        id: 1,
        account_id: 1,
        provider: :openai,
        model: "gpt-4.1",
        tokens: 42_120,
        cost_usd: 18.42,
        latency_ms: 830,
        status: :ok,
        inserted_at: "5m ago"
      },
      %Request{
        id: 2,
        account_id: 1,
        provider: :anthropic,
        model: "claude-sonnet-4",
        tokens: 91_004,
        cost_usd: 42.13,
        latency_ms: 1_240,
        status: :ok,
        inserted_at: "18m ago"
      },
      %Request{
        id: 3,
        account_id: 2,
        provider: :google,
        model: "gemini-3-pro",
        tokens: 18_400,
        cost_usd: 7.91,
        latency_ms: 2_100,
        status: :error,
        inserted_at: "42m ago"
      }
    ]
  end

  def total_requests(_variables, _context), do: length(list_requests())

  def total_cost(_variables, _context) do
    list_requests()
    |> Enum.map(& &1.cost_usd)
    |> Enum.sum()
    |> Float.round(2)
  end

  def avg_latency(_variables, _context) do
    requests = list_requests()
    round(Enum.sum(Enum.map(requests, & &1.latency_ms)) / max(length(requests), 1))
  end

  def error_rate(_variables, _context) do
    requests = list_requests()
    errors = Enum.count(requests, &(&1.status == :error))
    errors / max(length(requests), 1)
  end

  def requests_over_time(_variables, _context) do
    [
      %{label: "45m", value: 1},
      %{label: "30m", value: 0},
      %{label: "15m", value: 1},
      %{label: "now", value: 1}
    ]
  end

  def slow_requests(_variables, _context) do
    list_requests()
    |> Enum.filter(&(&1.latency_ms >= 1_000 or &1.status == :error))
    |> Enum.map(fn request ->
      %{
        provider: request.provider,
        model: request.model,
        latency_ms: request.latency_ms,
        cost_usd: request.cost_usd,
        status: request.status
      }
    end)
  end
end
