defmodule Playground.Admin.LLMRequestResource do
  @moduledoc false

  use Incant.Resource,
    schema: Playground.LLM.Request,
    repo: Playground.Repo

  query(&__MODULE__.index_query/2)

  table density: :compact, saved_views: true do
    column(:inserted_at, format: :relative)
    column(:provider, as: :badge)
    column(:model)
    column(:tokens, align: :right)
    column(:cost_usd, format: :currency)
    column(:latency_ms, align: :right)
    column(:status, as: :badge)

    filter(:provider, :multi_select, options: [:openai, :anthropic, :google])
    filter(:model, :select)
    filter(:inserted_at, :date_range)

    search([:model, :status])
  end

  def index_query(query, _context), do: query
end
