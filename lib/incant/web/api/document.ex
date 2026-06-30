defmodule Incant.Web.API.Document do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive Jason.Encoder
  defstruct [:data, links: %{}, meta: %{}]

  @type t :: %__MODULE__{data: term(), links: map(), meta: map()}

  @spec new(term(), keyword()) :: t()
  def new(data, opts \\ []) do
    %__MODULE__{
      data: data,
      links: Keyword.get(opts, :links, %{}),
      meta: Keyword.get(opts, :meta, %{})
    }
  end
end
