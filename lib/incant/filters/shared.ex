defmodule Incant.Filters.Shared do
  @moduledoc false

  def blank?(value), do: value in [nil, "", [], %{}]

  def custom_query?(%{query: query}), do: not is_nil(query)

  def row_value(row, field) do
    Map.get(row, field, Map.get(row, to_string(field), ""))
  end

  def apply_query_callback(%{query: query}, queryable, value, context)
      when is_function(query, 3) do
    query.(queryable, value, context)
  end

  def apply_query_callback(_filter, queryable, _value, _context), do: queryable

  def cast_query_value(filter, value, %{resource: %{schema: schema}}) do
    if is_atom(schema) and function_exported?(schema, :__schema__, 2) do
      cast_value(value, apply(schema, :__schema__, [:type, filter.name]))
    else
      value
    end
  end

  def cast_query_value(_filter, value, _context), do: value

  defp cast_value(value, :integer) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} -> integer
      _other -> value
    end
  end

  defp cast_value(value, :float) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> float
      _other -> value
    end
  end

  defp cast_value(value, :boolean), do: value in [true, "true", 1, "1"]

  defp cast_value(value, :date) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _error -> value
    end
  end

  defp cast_value(value, _type), do: value
end
