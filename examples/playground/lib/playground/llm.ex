defmodule Playground.LLM do
  @moduledoc false

  alias Playground.LLM.Request

  @models [
    {:openai, "gpt-4.1"},
    {:anthropic, "claude-sonnet-4"},
    {:google, "gemini-3-pro"}
  ]

  def list_requests(_params \\ %{}), do: requests()

  defp requests do
    Enum.map(1..24, &build_request/1)
  end

  defp build_request(id) do
    {provider, model} = Enum.at(@models, rem(id - 1, 3))
    tokens = 12_000 + rem(id * 7_319, 90_000)
    cost = Float.round(tokens / 4_000 + rem(id * 13, 40) / 10, 2)
    latency = 400 + rem(id * 971, 2_600)
    status = if rem(id, 8) == 0, do: :error, else: :ok

    %Request{
      id: id,
      account_id: 1 + rem(id, 2),
      provider: provider,
      model: model,
      tokens: tokens,
      cost_usd: cost,
      latency_ms: latency,
      status: status,
      inserted_at: "#{rem(id * 7, 55) + 2}m ago"
    }
  end

  def total_requests(_variables, _context), do: length(requests())

  def total_tokens(_variables, _context) do
    requests() |> Enum.map(& &1.tokens) |> Enum.sum()
  end

  def total_cost(_variables, _context) do
    requests()
    |> Enum.map(& &1.cost_usd)
    |> Enum.sum()
    |> Float.round(2)
  end

  def avg_latency(_variables, _context) do
    round(Enum.sum(Enum.map(requests(), & &1.latency_ms)) / max(length(requests()), 1))
  end

  def error_rate(_variables, _context) do
    errors = Enum.count(requests(), &(&1.status == :error))
    errors / max(length(requests()), 1)
  end

  def requests_over_time(_variables, _context) do
    [
      %{label: "6h", value: 3},
      %{label: "5h", value: 5},
      %{label: "4h", value: 2},
      %{label: "3h", value: 6},
      %{label: "2h", value: 4},
      %{label: "1h", value: 7},
      %{label: "now", value: 5}
    ]
  end

  def slow_requests(_variables, _context) do
    requests()
    |> Enum.filter(&(&1.latency_ms >= 1_500 or &1.status == :error))
    |> Enum.sort_by(& &1.latency_ms, :desc)
    |> Enum.take(8)
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
