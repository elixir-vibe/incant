defmodule Incant.Filters.Shared do
  @moduledoc false

  import Ecto.Query

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

  def apply_equal_query(filter, queryable, value, context) do
    if custom_query?(filter) or blank?(value) do
      apply_query_callback(filter, queryable, value, context)
    else
      where(
        queryable,
        [row],
        field(row, ^filter.name) == ^cast_query_value(filter, value, context)
      )
    end
  rescue
    _error in [ArgumentError, Ecto.QueryError] -> queryable
  end

  def cast_query_value(filter, value, %{resource: %{schema: schema}}) do
    with true <- is_atom(schema),
         true <- function_exported?(schema, :__schema__, 2),
         type when not is_nil(type) <- apply(schema, :__schema__, [:type, filter.name]),
         {:ok, casted} <- Ecto.Type.cast(type, value) do
      casted
    else
      _fallback -> value
    end
  end

  def cast_query_value(_filter, value, _context), do: value
end
