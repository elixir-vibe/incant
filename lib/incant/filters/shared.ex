defmodule Incant.Filters.Shared do
  @moduledoc false

  def blank?(value), do: value in [nil, "", [], %{}]

  def row_value(row, field) do
    Map.get(row, field, Map.get(row, to_string(field), ""))
  end

  def apply_query_callback(%{query: query}, queryable, value, context)
      when is_function(query, 3) do
    query.(queryable, value, context)
  end

  def apply_query_callback(_filter, queryable, _value, _context), do: queryable
end
