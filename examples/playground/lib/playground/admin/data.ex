defmodule Playground.Admin.Data do
  @moduledoc false

  alias Playground.Catalog.Product
  alias Playground.LLM.Request

  def products(_params) do
    [
      %Product{
        id: 1,
        name: "Incant Pro",
        status: :active,
        price: 149.0,
        inventory: 32,
        inserted_at: "2h ago"
      },
      %Product{
        id: 2,
        name: "Dashboard Wand",
        status: :draft,
        price: 79.0,
        inventory: 8,
        inserted_at: "1d ago"
      },
      %Product{
        id: 3,
        name: "CMS Grimoire",
        status: :archived,
        price: 229.0,
        inventory: 0,
        inserted_at: "5d ago"
      }
    ]
  end

  def llm_requests(_params) do
    [
      %Request{
        id: 1,
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
        provider: :anthropic,
        model: "claude-sonnet-4",
        tokens: 31_500,
        cost_usd: 22.10,
        latency_ms: 940,
        status: :ok,
        inserted_at: "8m ago"
      },
      %Request{
        id: 3,
        provider: :google,
        model: "gemini-3-pro",
        tokens: 9_840,
        cost_usd: 4.88,
        latency_ms: 1_820,
        status: :error,
        inserted_at: "14m ago"
      }
    ]
  end
end
