defmodule Incant.Service.Cell do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive {Jason.Encoder, only: [:column, :value]}
  defstruct [:column, :value]

  @type t :: %__MODULE__{column: String.t(), value: term()}
end
