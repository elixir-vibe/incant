defmodule Incant.Live.Rows do
  @moduledoc false

  def list(nil, _table_state), do: []

  def list(resource, table_state) do
    resource
    |> raw(table_state)
    |> search(resource.table.search, table_state.search)
    |> filter(resource.table.filters, table_state.filters)
    |> sort(table_state.sort)
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> []
  end

  def one(_resource, nil), do: nil

  def one(resource, id) do
    resource
    |> raw(%{})
    |> Enum.find(&(id(&1) == id))
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> nil
  end

  def raw(resource, table_state \\ %{})
  def raw(nil, _table_state), do: []

  def raw(%{data: data} = _resource, table_state) when not is_nil(data) do
    data
    |> Incant.Callback.call(%{table: table_state}, [])
    |> Incant.Tabular.to_rows()
  end

  def raw(%{repo: repo, schema: schema} = resource, table_state)
      when not is_nil(repo) and not is_nil(schema) do
    queryable = queryable(resource, table_state)

    repo
    |> apply(:all, [queryable])
    |> Incant.Tabular.to_rows()
  end

  def raw(_resource, _table_state), do: []

  def id(row), do: row |> field(:id) |> id_string()

  def title(row, resource) do
    link_column =
      Enum.find(resource.table.columns, & &1.opts[:link]) || List.first(resource.table.columns)

    case link_column do
      nil -> "Record #{id(row)}"
      column -> row |> field(column.name) |> to_string()
    end
  end

  def fields(%_struct{} = row) do
    row
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, format_detail_value(value)} end)
  end

  def fields(row) when is_map(row) do
    Enum.map(row, fn {key, value} -> {key, format_detail_value(value)} end)
  end

  def fields(_row), do: []

  def field(row, field) do
    Map.get(row, field, Map.get(row, to_string(field)))
  end

  defp queryable(resource, table_state) do
    queryable = base_queryable(resource, table_state)

    Incant.Filter.apply_filters(
      resource.table.filters,
      queryable,
      table_state_filters(table_state),
      %{
        resource: resource,
        table: table_state
      }
    )
  end

  defp base_queryable(%{query: nil, schema: schema}, _table_state), do: schema

  defp base_queryable(resource, table_state) do
    Incant.Callback.call(resource.query, resource.schema, %{table: table_state})
  end

  defp table_state_filters(%{filters: filters}), do: filters
  defp table_state_filters(_table_state), do: %{}

  defp id_string(nil), do: nil
  defp id_string(""), do: nil
  defp id_string(value), do: to_string(value)

  defp search(rows, nil, _search), do: rows
  defp search(rows, _searchable, nil), do: rows
  defp search(rows, _searchable, ""), do: rows

  defp search(rows, searchable, search) do
    fields = List.wrap(searchable)
    needle = String.downcase(search)

    Enum.filter(rows, fn row ->
      Enum.any?(fields, fn field ->
        row
        |> Map.get(field)
        |> to_string()
        |> String.downcase()
        |> String.contains?(needle)
      end)
    end)
  end

  defp filter(rows, _definitions, filters) when map_size(filters) == 0, do: rows

  defp filter(rows, definitions, filters) do
    filters_by_name = Map.new(definitions, &{to_string(&1.name), &1})

    Enum.filter(rows, fn row ->
      Enum.all?(filters, fn {field, value} ->
        case Map.fetch(filters_by_name, field) do
          {:ok, filter} -> Incant.Filter.match?(filter, row, value)
          :error -> true
        end
      end)
    end)
  end

  defp sort(rows, nil), do: rows
  defp sort(rows, ""), do: rows

  defp sort(rows, sort) do
    {direction, field} = sort_parts(sort)

    Enum.sort_by(
      rows,
      &Map.get(&1, String.to_existing_atom(field)),
      sort_direction_fun(direction)
    )
  rescue
    ArgumentError -> rows
  end

  defp sort_parts("-" <> field), do: {:desc, field}
  defp sort_parts(field), do: {:asc, field}

  defp sort_direction_fun(:desc), do: :desc
  defp sort_direction_fun(:asc), do: :asc

  defp format_detail_value(value) when is_binary(value), do: value
  defp format_detail_value(value), do: inspect(value)
end
