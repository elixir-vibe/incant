defmodule Incant.Live.Rows do
  @moduledoc false

  import Ecto.Query

  alias Incant.Live.Authorization

  def list(resource, table_state, context \\ %{})
  def list(nil, _table_state, _context), do: []
  def list(resource, table_state, context), do: page(resource, table_state, context).rows

  def page(resource, table_state, context \\ %{})
  def page(nil, table_state, context), do: page([], table_state, context)

  def page(%{repo: repo, schema: schema, index: nil} = resource, table_state, context)
      when not is_nil(repo) and not is_nil(schema) do
    page = Incant.Params.positive_integer(Map.get(table_state, :page), 1)
    page_size = Incant.Params.positive_integer(Map.get(table_state, :page_size), 25)
    total = query_count(resource, table_state, context)
    total_pages = max(ceil(total / page_size), 1)
    page = min(page, total_pages)
    table_state = table_state |> Map.put(:page, page) |> Map.put(:page_size, page_size)

    %{
      rows: raw(resource, table_state, [paginate: true], context),
      page: page,
      page_size: page_size,
      total: total,
      total_pages: total_pages,
      meta: %{options: distinct_filter_options(resource, context)}
    }
  rescue
    error in [
      ArgumentError,
      Ecto.QueryError,
      FunctionClauseError,
      Protocol.UndefinedError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      error_page(error, table_state)
  end

  def page(%{index: index} = resource, table_state, context) when not is_nil(index) do
    case load_index(resource, table_state, context) do
      %Incant.Result{} = result -> result_page(result, table_state)
      rows -> rows_page(process_rows(rows, resource, table_state), table_state)
    end
  rescue
    error in [
      ArgumentError,
      FunctionClauseError,
      Protocol.UndefinedError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      error_page(error, table_state)
  end

  def page(resource, table_state, context) do
    resource
    |> all(table_state, context)
    |> rows_page(table_state)
  rescue
    error in [
      ArgumentError,
      FunctionClauseError,
      Protocol.UndefinedError,
      RuntimeError,
      UndefinedFunctionError
    ] ->
      error_page(error, table_state)
  end

  defp all(resource, table_state, context) do
    resource
    |> raw(table_state, [], context)
    |> process_rows(resource, table_state)
  end

  defp process_rows(rows, resource, table_state) do
    rows
    |> search(resource.table.search, Map.get(table_state, :search))
    |> filter(resource.table.filters, Map.get(table_state, :filters, %{}))
    |> sort(Map.get(table_state, :sort))
  end

  defp rows_page(rows, table_state) do
    page = Incant.Params.positive_integer(Map.get(table_state, :page), 1)
    page_size = Incant.Params.positive_integer(Map.get(table_state, :page_size), 25)
    total = length(rows)
    total_pages = max(ceil(total / page_size), 1)
    page = min(page, total_pages)

    %{
      rows: paginate(rows, %{page: page, page_size: page_size}),
      page: page,
      page_size: page_size,
      total: total,
      total_pages: total_pages,
      meta: %{}
    }
  end

  defp result_page(%Incant.Result{} = result, table_state) do
    page = Incant.Params.positive_integer(Map.get(result.meta, :page, table_state[:page]), 1)

    page_size =
      Incant.Params.positive_integer(
        Map.get(result.meta, :page_size, table_state[:page_size]),
        25
      )

    total = result.total_count || length(result.rows)
    total_pages = max(ceil(total / page_size), 1)

    %{
      rows: result.rows,
      page: min(page, total_pages),
      page_size: page_size,
      total: total,
      total_pages: total_pages,
      meta: Map.drop(result.meta, [:page, :page_size])
    }
  end

  def one(resource, id, context \\ %{})
  def one(_resource, nil, _context), do: nil

  def one(%{read: read} = resource, id, context) when not is_nil(read) do
    read
    |> Incant.Callback.call(id, context)
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

  defp error_page(error, table_state) do
    page = Incant.Params.positive_integer(Map.get(table_state, :page), 1)
    page_size = Incant.Params.positive_integer(Map.get(table_state, :page_size), 25)

    %{
      rows: [],
      page: page,
      page_size: page_size,
      total: 0,
      total_pages: 1,
      error: Exception.message(error)
    }
  end

  def raw(resource, table_state \\ %{}, opts \\ [], context \\ %{})
  def raw(nil, _table_state, _opts, _context), do: []

  def raw(%{index: index} = resource, table_state, _opts, context) when not is_nil(index) do
    case load_index(resource, table_state, context) do
      %Incant.Result{rows: rows} -> rows
      rows -> rows
    end
  end

  def raw(%{repo: repo, schema: schema} = resource, table_state, opts, context)
      when not is_nil(repo) and not is_nil(schema) do
    queryable = queryable(resource, table_state, Keyword.get(opts, :paginate, false), context)

    repo
    |> apply(:all, [queryable])
    |> Incant.Tabular.to_rows()
  end

  def raw(_resource, _table_state, _opts, _context), do: []

  defp load_index(resource, table_state, context) do
    result = Incant.Callback.call(resource.index, %{table: table_state}, context)

    case result do
      %Incant.Result{} = result ->
        %{result | rows: result.rows |> Incant.Tabular.to_rows() |> scope_rows(resource, context)}

      rows ->
        rows
        |> Incant.Tabular.to_rows()
        |> scope_rows(resource, context)
    end
  end

  def id(%Incant.Service.Row{id: id}), do: id_string(id)
  def id(row), do: row |> field(:id) |> id_string()

  def title(row, resource) do
    link_column =
      Enum.find(resource.table.columns, & &1.opts[:link]) || List.first(resource.table.columns)

    case link_column do
      nil -> "Record #{id(row)}"
      column -> row |> field(column.name) |> to_string()
    end
  end

  def fields(%Incant.Service.Row{} = row) do
    Enum.map(row.cells, fn %Incant.Service.Cell{column: column, value: value} ->
      {column, format_detail_value(value)}
    end)
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

  def field(%Incant.Service.Row{id: id}, field) when field in [:id, "id"], do: id

  def field(%Incant.Service.Row{} = row, field) do
    field = to_string(field)

    Enum.reduce_while(row.cells, nil, fn %Incant.Service.Cell{column: column, value: value},
                                         _acc ->
      if column == field, do: {:halt, value}, else: {:cont, nil}
    end)
  end

  def field(row, field) do
    Map.get(row, field, Map.get(row, to_string(field)))
  end

  defp queryable(resource, table_state, paginate?, context) do
    queryable = resource |> base_queryable(table_state, context) |> scope_query(resource, context)

    query_context = %{
      resource: resource,
      table: table_state,
      actor: Map.get(context, :actor)
    }

    filtered =
      resource.table.filters
      |> Incant.Filter.apply_filters(
        apply_query_search(queryable, resource, table_state, query_context),
        table_state_filters(table_state),
        query_context
      )

    if paginate? do
      filtered
      |> sort_query(resource, table_state)
      |> paginate_query(table_state)
    else
      filtered
    end
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
    _error in [ArgumentError, FunctionClauseError, UndefinedFunctionError, RuntimeError] -> nil
  end

  defp subquery_count(repo, %Ecto.Query{} = queryable) do
    count_query =
      queryable
      |> exclude(:order_by)
      |> subquery()
      |> select([row], count(row))

    apply(repo, :one, [count_query])
  rescue
    _error in [ArgumentError, FunctionClauseError, UndefinedFunctionError, Ecto.QueryError] -> nil
  end

  defp subquery_count(_repo, _queryable), do: nil

  defp paginate_query(queryable, %{page: page, page_size: page_size}) do
    page = Incant.Params.positive_integer(page, 1)
    page_size = Incant.Params.positive_integer(page_size, 25)

    queryable
    |> limit(^page_size)
    |> offset(^((page - 1) * page_size))
  rescue
    _error in [ArgumentError, Ecto.QueryError, FunctionClauseError, Protocol.UndefinedError] ->
      queryable
  end

  defp paginate_query(queryable, _table_state), do: queryable

  defp table_state_filters(%{filters: filters}), do: filters
  defp table_state_filters(_table_state), do: %{}

  defp apply_query_search(queryable, _resource, %{search: search}, _context)
       when search in [nil, ""],
       do: queryable

  defp apply_query_search(
         queryable,
         %{table: %{search: fields}} = resource,
         table_state,
         _context
       )
       when is_list(fields) or is_atom(fields) do
    fields = Enum.filter(List.wrap(fields), &searchable_field?(resource, &1))

    case {fields, Map.get(table_state, :search)} do
      {[], _term} -> queryable
      {_fields, term} when term in [nil, ""] -> queryable
      {fields, term} -> search_fields(queryable, fields, term)
    end
  end

  defp apply_query_search(queryable, %{table: %{search: callback}}, table_state, context)
       when is_function(callback) or is_tuple(callback) do
    Incant.Callback.call(callback, queryable, %{
      search: Map.get(table_state, :search),
      table: table_state,
      context: context
    })
  end

  defp apply_query_search(queryable, _resource, _table_state, _context), do: queryable

  defp search_fields(queryable, fields, term) do
    pattern = "%#{term}%"

    expression =
      Enum.reduce(fields, dynamic(false), fn field_name, expression ->
        dynamic(
          [row],
          ^expression or
            fragment("lower(?) LIKE lower(?)", field(row, ^field_name), ^pattern)
        )
      end)

    where(queryable, ^expression)
  end

  defp searchable_field?(%{schema: schema}, field_name) do
    schema_field_type(schema, field_name) in [:string, :binary_id]
  end

  defp sort_query(%Ecto.Query{} = queryable, resource, table_state) do
    allowed_fields =
      resource.table.columns
      |> Enum.reject(&(metadata_opt(&1.opts, :sortable, true) == false))
      |> Enum.map(& &1.name)
      |> Enum.filter(&(not is_nil(schema_field_type(resource.schema, &1))))

    Incant.Ecto.sort(queryable, table_state, allowed_fields,
      default: default_sort(resource.table.opts),
      tie_breaker: primary_key(resource)
    )
  end

  defp sort_query(queryable, _resource, _table_state), do: queryable

  defp default_sort(opts) do
    case metadata_opt(opts, :default_sort, nil) do
      [{field_name, direction} | _rest] -> {field_name, direction}
      {field_name, direction} -> {field_name, direction}
      _other -> nil
    end
  end

  defp distinct_filter_options(resource, context) do
    case resource.repo do
      nil ->
        %{}

      repo ->
        queryable = resource |> base_queryable(%{}, context) |> scope_query(resource, context)

        resource.table.filters
        |> Enum.filter(&(metadata_opt(&1.opts, :options, nil) == :distinct))
        |> Map.new(fn filter ->
          {to_string(filter.name), distinct_options(repo, queryable, resource, filter)}
        end)
    end
  rescue
    _error in [ArgumentError, Ecto.QueryError, RuntimeError, UndefinedFunctionError] -> %{}
  end

  defp distinct_options(repo, queryable, resource, filter) do
    if schema_field_type(resource.schema, filter.name) do
      field_name = filter.name
      limit = metadata_opt(filter.opts, :option_limit, 100)

      queryable
      |> exclude(:select)
      |> exclude(:order_by)
      |> where([row], not is_nil(field(row, ^field_name)))
      |> distinct(true)
      |> order_by([row], asc: field(row, ^field_name))
      |> select([row], field(row, ^field_name))
      |> limit(^limit)
      |> then(&apply(repo, :all, [&1]))
      |> Enum.map(&%{label: to_string(&1), value: &1})
    else
      []
    end
  end

  defp schema_field_type(schema, field_name) when is_atom(schema) and is_atom(field_name) do
    if function_exported?(schema, :__schema__, 2),
      do: apply(schema, :__schema__, [:type, field_name])
  end

  defp schema_field_type(_schema, _field_name), do: nil

  defp metadata_opt(opts, key, default) when is_list(opts) or is_map(opts) do
    opts = Map.new(opts)
    Map.get(opts, key, Map.get(opts, to_string(key), default))
  end

  defp metadata_opt(_opts, _key, default), do: default

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
    page = Incant.Params.positive_integer(Map.get(table_state, :page), 1)
    page_size = Incant.Params.positive_integer(Map.get(table_state, :page_size), 25)

    Enum.slice(rows, (page - 1) * page_size, page_size)
  end

  defp sort_parts("-" <> field), do: {:desc, field}
  defp sort_parts(field), do: {:asc, field}

  defp sort_direction_fun(:desc), do: :desc
  defp sort_direction_fun(:asc), do: :asc

  defp format_detail_value(value) when is_binary(value), do: value
  defp format_detail_value(value), do: inspect(value)
end
