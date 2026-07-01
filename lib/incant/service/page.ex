defmodule Incant.Service.Page do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive {Jason.Encoder, only: [:rows, :page, :page_size, :total, :total_pages, :error]}
  defstruct rows: [], page: 1, page_size: 25, total: 0, total_pages: 1, error: nil

  @type t :: %__MODULE__{
          rows: [Incant.Service.Row.t()],
          page: pos_integer(),
          page_size: pos_integer(),
          total: non_neg_integer(),
          total_pages: pos_integer(),
          error: String.t() | nil
        }

  @spec from_resource_page(map(), map()) :: t()
  def from_resource_page(page, resource) when is_map(page) do
    %__MODULE__{
      rows:
        page |> Map.get(:rows, []) |> Enum.map(&Incant.Service.Row.from_resource(resource, &1)),
      page: Map.get(page, :page, 1),
      page_size: Map.get(page, :page_size, 25),
      total: Map.get(page, :total, 0),
      total_pages: Map.get(page, :total_pages, 1),
      error: Map.get(page, :error)
    }
  end

  @spec from_external(map()) :: t()
  def from_external(page) when is_map(page), do: from_map!(page)
end
