defmodule Incant.Tabular do
  @moduledoc """
  Normalizes common tabular data shapes into rows, columns, and metadata.
  """

  @type column :: atom | String.t()
  @type metadata :: %{required(:columns) => [column], optional(:count) => non_neg_integer}

  @doc """
  Returns metadata for tabular data.
  """
  @spec metadata(term) :: metadata
  def metadata(data) do
    rows = to_rows(data)
    %{columns: columns(data, rows), count: Enum.count(rows)}
  end

  @doc """
  Converts tabular data to a list of row maps.
  """
  @spec to_rows(term, keyword) :: [map]
  def to_rows(data, opts \\ []) do
    data
    |> rows()
    |> only(opts[:only])
  end

  @doc """
  Converts tabular data to a map of column enumerables.
  """
  @spec to_columns(term, keyword) :: %{optional(column) => [term]}
  def to_columns(data, opts \\ []) do
    rows = to_rows(data, opts)
    columns = columns(data, rows) |> only_columns(opts[:only])

    Map.new(columns, fn column ->
      {column, Enum.map(rows, &Map.get(&1, column))}
    end)
  end

  defp rows([]), do: []

  defp rows(data) when is_list(data) do
    if column_tuple_list?(data) do
      rows_from_columns(data)
    else
      Enum.map(data, &row/1)
    end
  end

  defp rows(data) when is_map(data) do
    if column_map?(data) do
      rows_from_columns(Map.to_list(data))
    else
      [row(data)]
    end
  end

  defp rows(data), do: raise(ArgumentError, "cannot read #{inspect(data)} as tabular data")

  defp row(%{__struct__: _struct} = data) do
    data
    |> Map.from_struct()
    |> Map.new(fn {key, value} -> {normalize_key(key), value} end)
  end

  defp row(data) when is_map(data) do
    Map.new(data, fn {key, value} -> {normalize_key(key), value} end)
  end

  defp row(data) when is_list(data) do
    Map.new(data, fn {key, value} -> {normalize_key(key), value} end)
  end

  defp rows_from_columns(columns) do
    normalized =
      Enum.map(columns, fn {key, values} -> {normalize_key(key), Enum.to_list(values)} end)

    keys = Enum.map(normalized, &elem(&1, 0))
    values = Enum.map(normalized, &elem(&1, 1))

    values
    |> Enum.zip()
    |> Enum.map(fn row_values -> keys |> Enum.zip(Tuple.to_list(row_values)) |> Map.new() end)
  end

  defp columns(data, rows) when is_map(data) do
    if column_map?(data),
      do: Enum.map(data, &normalize_key(elem(&1, 0))),
      else: columns_from_rows(rows)
  end

  defp columns(data, rows) when is_list(data) do
    if column_tuple_list?(data),
      do: Enum.map(data, &normalize_key(elem(&1, 0))),
      else: columns_from_rows(rows)
  end

  defp columns(_data, rows), do: columns_from_rows(rows)

  defp columns_from_rows([]), do: []
  defp columns_from_rows([row | _]), do: Map.keys(row)

  defp column_map?(data) do
    map_size(data) > 0 and Enum.all?(data, fn {_key, value} -> enumerable_values?(value) end)
  end

  defp column_tuple_list?(data) do
    Enum.all?(data, fn
      {key, value} when is_atom(key) or is_binary(key) -> enumerable_values?(value)
      _other -> false
    end)
  end

  defp enumerable_values?(value), do: Enumerable.impl_for(value) != nil and not is_binary(value)

  defp only(rows, nil), do: rows

  defp only(rows, columns) do
    columns = Enum.map(columns, &normalize_key/1)
    Enum.map(rows, &Map.take(&1, columns))
  end

  defp only_columns(columns, nil), do: columns

  defp only_columns(columns, only),
    do: Enum.filter(columns, &(&1 in Enum.map(only, fn item -> normalize_key(item) end)))

  defp normalize_key(key) when is_atom(key) or is_binary(key), do: key
end
