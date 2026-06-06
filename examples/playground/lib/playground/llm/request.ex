defmodule Playground.LLM.Request do
  @moduledoc false

  defstruct [
    :id,
    :account_id,
    :provider,
    :model,
    :tokens,
    :cost_usd,
    :latency_ms,
    :status,
    :inserted_at
  ]
end
