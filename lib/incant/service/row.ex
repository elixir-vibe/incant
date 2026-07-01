defmodule Incant.Service.Row do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive {Jason.Encoder, only: [:id, :cells]}
  defstruct [:id, cells: []]

  @type t :: %__MODULE__{id: String.t() | nil, cells: [Incant.Service.Cell.t()]}

  @spec from_resource(map(), term()) :: t()
  def from_resource(resource, row) do
    %__MODULE__{
      id: Incant.Live.Rows.id(row),
      cells: Enum.map(columns(resource), &cell(row, &1))
    }
  end

  @spec from_external(map()) :: t()
  def from_external(row) when is_map(row), do: from_map!(row)

  defp columns(%{table: %{columns: columns}}) when is_list(columns), do: columns
  defp columns(_resource), do: []

  defp cell(row, column) do
    %Incant.Service.Cell{column: to_string(column.name), value: value(row, column)}
  end

  defp value(row, column) do
    row
    |> Incant.Live.Rows.field(column.name)
    |> external_value()
  end

  defp external_value(nil), do: nil
  defp external_value(value) when is_binary(value), do: value
  defp external_value(value) when is_boolean(value), do: value
  defp external_value(value) when is_integer(value), do: value
  defp external_value(value) when is_float(value), do: value
  defp external_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp external_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp external_value(%Date{} = value), do: Date.to_iso8601(value)
  defp external_value(%Time{} = value), do: Time.to_iso8601(value)
  defp external_value(%Decimal{} = value), do: Decimal.to_string(value)
  defp external_value(value) when is_atom(value), do: Atom.to_string(value)
  defp external_value(value), do: inspect(value)
end
