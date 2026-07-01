defmodule Incant.Service.Page do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  defstruct rows: [], page: 1, page_size: 25, total: 0, total_pages: 1, error: nil

  @type t :: %__MODULE__{
          rows: [map()],
          page: pos_integer(),
          page_size: pos_integer(),
          total: non_neg_integer(),
          total_pages: pos_integer(),
          error: String.t() | nil
        }

  @spec to_external(map()) :: map()
  def to_external(page) when is_map(page) do
    page
    |> JSONCodec.dump()
    |> from_map!()
    |> JSONCodec.dump()
  end

  @spec from_external(map()) :: map()
  def from_external(page) when is_map(page), do: page |> from_map!() |> Map.from_struct()
end
