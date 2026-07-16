defmodule Incant.Ecto do
  @moduledoc """
  Small Ecto helpers for application-owned Incant resource queries.

  Applications retain ownership of filtering, joins, projections, and
  authorization. These helpers only apply normalized table sorting and exact
  offset pagination.
  """

  import Ecto.Query

  @type page :: %{
          page: pos_integer(),
          page_size: pos_integer(),
          total: non_neg_integer(),
          total_pages: pos_integer()
        }

  @doc "Applies an allowlisted table sort with a deterministic tie-breaker."
  @spec sort(Ecto.Queryable.t(), map(), [atom()], keyword()) :: Ecto.Query.t()
  def sort(queryable, table_state, allowed_fields, opts \\ []) do
    queryable = Ecto.Queryable.to_query(queryable)
    default = Keyword.get(opts, :default)
    tie_breaker = Keyword.get(opts, :tie_breaker, :id)

    case requested_sort(table_state, allowed_fields) || default do
      {field, direction} -> order(queryable, field, direction, tie_breaker)
      nil -> queryable
    end
  end

  @doc "Counts, clamps, and applies exact offset pagination to a query."
  @spec page(Ecto.Queryable.t(), module(), map()) :: {Ecto.Query.t(), page()}
  def page(queryable, repo, table_state) do
    page_size = table_state |> value(:page_size) |> Incant.Params.positive_integer(25)
    requested_page = table_state |> value(:page) |> Incant.Params.positive_integer(1)
    total = apply(repo, :aggregate, [queryable, :count, :id])
    total_pages = max(ceil(total / page_size), 1)
    page = min(requested_page, total_pages)

    query =
      queryable
      |> limit(^page_size)
      |> offset(^((page - 1) * page_size))

    {query, %{page: page, page_size: page_size, total: total, total_pages: total_pages}}
  end

  defp requested_sort(table_state, allowed_fields) do
    case value(table_state, :sort) do
      "-" <> name -> allowed_sort(name, :desc, allowed_fields)
      name when is_binary(name) and name != "" -> allowed_sort(name, :asc, allowed_fields)
      _other -> nil
    end
  end

  defp allowed_sort(name, direction, allowed_fields) do
    case Enum.find(allowed_fields, &(to_string(&1) == name)) do
      nil -> nil
      field -> {field, direction}
    end
  end

  defp order(queryable, field, direction, field),
    do: order_by(queryable, [row], [{^direction, field(row, ^field)}])

  defp order(queryable, field, direction, tie_breaker) do
    order_by(queryable, [row], [
      {^direction, field(row, ^field)},
      {^direction, field(row, ^tie_breaker)}
    ])
  end

  defp value(map, key) when is_map(map),
    do: Map.get(map, key, Map.get(map, to_string(key)))

  defp value(_other, _key), do: nil
end
