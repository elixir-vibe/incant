defmodule Playground.Admin.Resources.LLMRequest do
  @moduledoc false

  alias Playground.Admin.Data

  use Incant.Resource,
    schema: Playground.LLM.Request,
    repo: Playground.Repo

  query(&__MODULE__.index_query/2)
  data(&Data.llm_requests/1)

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

    transformer :expensive_slow_requests, label: "Expensive slow requests" do
      query_transformer(&__MODULE__.expensive_slow_requests/3)
    end

    search([:model, :status])
  end

  def index_query(query, _context), do: query
  def expensive_slow_requests(query, _params, _context), do: query
end
