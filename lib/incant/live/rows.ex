defmodule Incant.Live.Rows do
  @moduledoc false

  import Ecto.Query

  alias Incant.Live.Authorization

  def list(resource, table_state, context \\ %{})
  def list(nil, _table_state, _context), do: []
  def list(resource, table_state, context), do: page(resource, table_state, context).rows

  def page(resource, table_state, context \\ %{})
  def page(nil, table_state, context), do: page([], table_state, context)

  def page(%{repo: repo, schema: schema, data: nil} = resource, table_state, context)
      when not is_nil(repo) and not is_nil(schema) do
    page = positive_integer(Map.get(table_state, :page), 1)
    page_size = positive_integer(Map.get(table_state, :page_size), 25)
    total = query_count(resource, table_state, context)
    total_pages = max(ceil(total / page_size), 1)
    page = min(page, total_pages)
    table_state = table_state |> Map.put(:page, page) |> Map.put(:page_size, page_size)

    %{
      rows: raw(resource, table_state, [paginate: true], context),
      page: page,
      page_size: page_size,
      total: total,
      total_pages: total_pages
    }
  end

  def page(resource, table_state, context) do
    rows = all(resource, table_state, context)
    page = positive_integer(Map.get(table_state, :page), 1)
    page_size = positive_integer(Map.get(table_state, :page_size), 25)
    total = length(rows)
    total_pages = max(ceil(total / page_size), 1)
    page = min(page, total_pages)

    %{
      rows: paginate(rows, %{page: page, page_size: page_size}),
      page: page,
      page_size: page_size,
      total: total,
      total_pages: total_pages
    }
  end

  defp all(resource, table_state, context) do
    resource
    |> raw(table_state, [], context)
    |> search(resource.table.search, table_state.search)
    |> filter(resource.table.filters, table_state.filters)
    |> sort(table_state.sort)
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> []
  end

  def one(resource, id, context \\ %{})
  def one(_resource, nil, _context), do: nil

  def one(%{repo: repo, schema: schema} = resource, id, context)
      when not is_nil(repo) and not is_nil(schema) do
    queryable =
      resource
      |> queryable(%{}, false, context)
      |> filter_by_id(resource, id)

    repo
    |> apply(:one, [queryable])
    |> normalize_one()
  rescue
    _error in [
      ArgumentError,
      FunctionClauseError,
      Protocol.UndefinedError,
      UndefinedFunctionError
    ] ->
      one_from_rows(resource, id, context)
  end

  def one(resource, id, context), do: one_from_rows(resource, id, context)

  defp one_from_rows(resource, id, context) do
    resource
    |> raw(%{}, [], context)
    |> Enum.find(&(id(&1) == id))
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> nil
  end

  defp normalize_one(nil), do: nil
  defp normalize_one(row), do: row

  def raw(resource, table_state \\ %{}, opts \\ [], context \\ %{})
  def raw(nil, _table_state, _opts, _context), do: []

  def raw(%{data: data} = resource, table_state, _opts, context) when not is_nil(data) do
    data
    |> Incant.Callback.call(%{table: table_state}, [])
    |> Incant.Tabular.to_rows()
    |> scope_rows(resource, context)
  end

  def raw(%{repo: repo, schema: schema} = resource, table_state, opts, context)
      when not is_nil(repo) and not is_nil(schema) do
    queryable = queryable(resource, table_state, Keyword.get(opts, :paginate, false), context)

    repo
    |> apply(:all, [queryable])
    |> Incant.Tabular.to_rows()
  end

  def raw(_resource, _table_state, _opts, _context), do: []

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

  defp queryable(resource, table_state, paginate?, context) do
    queryable = resource |> base_queryable(table_state, context) |> scope_query(resource, context)

    filtered =
      Incant.Filter.apply_filters(
        resource.table.filters,
        queryable,
        table_state_filters(table_state),
        %{
          resource: resource,
          table: table_state,
          actor: Map.get(context, :actor)
        }
      )

    if paginate?, do: paginate_query(filtered, table_state), else: filtered
  end

  defp base_queryable(%{query: nil, schema: schema}, _table_state, _context) do
    if function_exported?(schema, :__schema__, 1), do: from(row in schema), else: schema
  end

  defp base_queryable(resource, table_state, context) do
    Incant.Callback.call(resource.query, resource.schema, %{
      table: table_state,
      actor: Map.get(context, :actor)
    })
  end

  defp scope_query(queryable, resource, %{admin: admin, actor: actor} = context) do
    case Authorization.policy(admin, :view_resource, Map.put(context, :resource, resource)) do
      nil ->
        queryable

      policy when is_atom(policy) ->
        if function_exported?(policy, :scope_query, 4) do
          apply(policy, :scope_query, [actor, resource, queryable, context])
        else
          queryable
        end
    end
  end

  defp scope_query(queryable, _resource, _context), do: queryable

  defp scope_rows(rows, resource, %{admin: admin, actor: actor} = context) do
    case Authorization.policy(admin, :view_resource, Map.put(context, :resource, resource)) do
      nil ->
        rows

      policy when is_atom(policy) ->
        if function_exported?(policy, :scope_rows, 4) do
          apply(policy, :scope_rows, [actor, resource, rows, context])
        else
          rows
        end
    end
  end

  defp scope_rows(rows, _resource, _context), do: rows

  defp filter_by_id(%Ecto.Query{} = queryable, resource, id) do
    primary_key = primary_key(resource)
    id = cast_id(resource, primary_key, id)

    where(queryable, [row], field(row, ^primary_key) == ^id)
  end

  defp filter_by_id(queryable, _resource, _id), do: queryable

  defp primary_key(%{schema: schema}) when is_atom(schema) do
    if function_exported?(schema, :__schema__, 1) do
      schema |> apply(:__schema__, [:primary_key]) |> List.first() || :id
    else
      :id
    end
  end

  defp primary_key(_resource), do: :id

  defp cast_id(%{schema: schema}, field, id) when is_atom(schema) do
    with true <- function_exported?(schema, :__schema__, 2),
         type when not is_nil(type) <- apply(schema, :__schema__, [:type, field]),
         {:ok, casted} <- Ecto.Type.cast(type, id) do
      casted
    else
      _fallback -> id
    end
  end

  defp cast_id(_resource, _field, id), do: id

  defp query_count(%{repo: repo} = resource, table_state, context) do
    queryable = queryable(resource, table_state, false, context)

    aggregate_count(repo, queryable) || subquery_count(repo, queryable) ||
      length(raw(resource, table_state, [], context))
  end

  defp aggregate_count(repo, queryable) do
    apply(repo, :aggregate, [queryable, :count])
  rescue
    _error -> nil
  end

  defp subquery_count(repo, %Ecto.Query{} = queryable) do
    count_query =
      queryable
      |> exclude(:order_by)
      |> subquery()
      |> select([row], count(row))

    apply(repo, :one, [count_query])
  rescue
    _error -> nil
  end

  defp subquery_count(_repo, _queryable), do: nil

  defp paginate_query(queryable, %{page: page, page_size: page_size}) do
    page = positive_integer(page, 1)
    page_size = positive_integer(page_size, 25)

    queryable
    |> limit(^page_size)
    |> offset(^((page - 1) * page_size))
  rescue
    _error -> queryable
  end

  defp paginate_query(queryable, _table_state), do: queryable

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

  defp paginate(rows, table_state) do
    page = positive_integer(Map.get(table_state, :page), 1)
    page_size = positive_integer(Map.get(table_state, :page_size), 25)

    rows
    |> Enum.drop((page - 1) * page_size)
    |> Enum.take(page_size)
  end

  defp positive_integer(value, _default) when is_integer(value) and value > 0, do: value

  defp positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _other -> default
    end
  end

  defp positive_integer(_value, default), do: default

  defp sort_parts("-" <> field), do: {:desc, field}
  defp sort_parts(field), do: {:asc, field}

  defp sort_direction_fun(:desc), do: :desc
  defp sort_direction_fun(:asc), do: :asc

  defp format_detail_value(value) when is_binary(value), do: value
  defp format_detail_value(value), do: inspect(value)
end
