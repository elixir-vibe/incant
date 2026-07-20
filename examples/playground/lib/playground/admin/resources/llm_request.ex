defmodule Playground.Admin.Resources.LLMRequest do
  @moduledoc false

  use Incant.Resource,
    schema: Playground.LLM.Request

  alias Playground.LLM

  alias Playground.LLM

  index(&LLM.list_requests/1)

  table density: :compact, saved_views: true do
    column(:inserted_at, format: :relative)
    column(:provider, as: :badge)
    column(:model, link: true)
    column(:tokens, label: "Tokens", format: :compact_number, align: :right)
    column(:cost_usd, label: "Cost", format: :money, align: :right)
    column(:latency_ms, label: "Latency", format: :duration_ms, align: :right)
    column(:status, as: :badge)

    filter(:provider, :multi_select, options: [:openai, :anthropic, :google])
    filter(:model, :select, options: ["gpt-4.1", "claude-sonnet-4", "gemini-3-pro"])
    filter(:inserted_at, :date_range)

    search([:model, :status])
  end
end
