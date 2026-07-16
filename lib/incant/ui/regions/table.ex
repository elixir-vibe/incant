defmodule Incant.UI.Regions.Table do
  @moduledoc """
  Resource table model.
  """

  defstruct [
    :id,
    columns: [],
    rows: [],
    sort: nil,
    pagination: nil,
    row_actions: [],
    bulk_actions: [],
    page_actions: [],
    row_detail: nil,
    selection: nil,
    empty_state: nil,
    loading: false,
    density: :compact
  ]

  defmodule Column do
    @moduledoc false
    defstruct [:id, :label, :align, :sortable, :format, :width, :priority, :source]
  end

  defmodule Row do
    @moduledoc false
    defstruct [:id, :actions, cells: [], detail: nil, event: nil, source: nil]
  end

  defmodule RowDetail do
    @moduledoc false
    defstruct [:id, :label, :kind, :source]
  end

  defmodule Selection do
    @moduledoc false
    defstruct selected_ids: [], enabled: false
  end

  defmodule Cell do
    @moduledoc false
    defstruct [:column, :value, :display, :tone, :format, :source]
  end

  def from_context(context) do
    resource = context.resource

    columns = Enum.map(resource.table.columns, &column_from_metadata/1)
    rows = Enum.map(context.rows || [], &row_from_record(&1, resource, context))

    %__MODULE__{
      id: "resource.table",
      columns: columns,
      rows: rows,
      sort: context.table_state.sort,
      pagination: context.pagination,
      row_actions: resource.table.actions,
      bulk_actions: resource.table.bulk_actions,
      page_actions: resource.table.page_actions,
      row_detail: row_detail_from_metadata(resource.table.row_detail),
      selection: selection_from_metadata(resource.table, context.table_state.selected_ids),
      empty_state: empty_state(context.pagination, context.table_state),
      density: resource.table.opts[:density] || :compact
    }
  end

  def from_dataset_context(context) do
    result = context.dataset_result || %Incant.Result{}
    columns = Enum.map(result_columns(context.dataset, result), &dataset_column/1)
    rows = Enum.map(result.rows || [], &dataset_row(&1, columns))

    %__MODULE__{
      id: "dataset.table",
      columns: columns,
      rows: rows,
      sort: context.table_state.sort,
      pagination: dataset_pagination(context, result),
      empty_state: dataset_empty_state(result, context.table_state),
      density: context.dataset.table.opts[:density] || :compact
    }
  end

  defp column_from_metadata(column) do
    %Column{
      id: to_string(column.name),
      label: column.opts[:label] || humanize(column.name),
      align: column.opts[:align],
      sortable: metadata_opt(column.opts, :sortable, true),
      format: column.opts[:format],
      width: column.opts[:width],
      priority: column.opts[:priority],
      source: column
    }
  end

  defp row_from_record(record, resource, context) do
    %Row{
      id: Incant.Live.Rows.id(record),
      cells: Enum.map(resource.table.columns, &cell_from_record(record, &1)),
      actions: available_actions(resource.table.actions, record, context),
      detail: row_detail_from_metadata(resource.table.row_detail),
      source: Incant.Sensitive.redact_row(record, resource)
    }
  end

  defp available_actions(actions, %Incant.Service.Row{available_actions: available}, _context)
       when is_list(available) do
    Enum.filter(actions, &(to_string(&1.name) in available))
  end

  defp available_actions(actions, row, context) do
    Enum.filter(actions, &Incant.Table.Action.available?(&1, row, context))
  end

  defp row_detail_from_metadata(nil), do: nil

  defp row_detail_from_metadata({name, opts}) do
    %RowDetail{
      id: to_string(name),
      label: opts[:label] || humanize(name),
      kind: opts[:kind] || opts[:type] || :panel,
      source: {name, opts}
    }
  end

  defp row_detail_from_metadata(%{opts: opts} = metadata) do
    name = metadata[:name] || metadata[:id]

    %RowDetail{
      id: to_string(name),
      label: opts[:label] || humanize(name),
      kind: opts[:kind] || opts[:type] || :panel,
      source: metadata
    }
  end

  defp selection_from_metadata(table, selected_ids) do
    %Selection{
      enabled: table.bulk_actions != [],
      selected_ids: Enum.map(selected_ids, &to_string/1)
    }
  end

  defp cell_from_record(record, column) do
    value = Incant.Live.Rows.field(record, column.name)
    display_value = Incant.Sensitive.redact(value, column.opts)

    format = column.opts[:as] || column.opts[:format]

    %Cell{
      column: to_string(column.name),
      value: display_value,
      display: cell_display(display_value, format, column.opts),
      tone: column.opts[:tone],
      format: format,
      source: column
    }
  end

  defp cell_display(true, :boolean, opts), do: opts[:true_label] || "Yes"
  defp cell_display(false, :boolean, opts), do: opts[:false_label] || "No"
  defp cell_display(value, format, _opts), do: Incant.Live.Format.value(value, format)

  defp dataset_column(column) do
    %Column{
      id: to_string(column),
      label: humanize(column),
      sortable: true,
      source: %{opts: []}
    }
  end

  defp dataset_row(row, columns) do
    %Row{
      id: row_id(row),
      cells: Enum.map(columns, &dataset_cell(row, &1)),
      source: row
    }
  end

  defp dataset_cell(row, column) do
    key = column_key(column.id, row)
    value = Map.get(row, key)

    %Cell{
      column: column.id,
      value: value,
      display: Incant.Live.Format.value(value, column.format),
      format: column.format,
      source: column.source
    }
  end

  defp result_columns(%{table: %{columns: [_ | _] = columns}}, _result), do: columns
  defp result_columns(_dataset, %{columns: columns}), do: columns

  defp dataset_pagination(context, result) do
    page_size = Incant.Params.positive_integer(context.table_state.page_size, 25)
    total = result.total_count || length(result.rows || [])

    %{
      page: Incant.Params.positive_integer(context.table_state.page, 1),
      page_size: page_size,
      total: total,
      total_pages: max(ceil(total / page_size), 1)
    }
  end

  defp empty_state(%{error: error}, _table_state) when is_binary(error),
    do: "Resource query failed: #{error}"

  defp empty_state(_pagination, table_state),
    do: empty_results_message(table_state, "No records yet.")

  defp dataset_empty_state(%{meta: %{error: reason}}, _table_state),
    do: "Dataset query failed: #{inspect(reason)}"

  defp dataset_empty_state(_result, table_state),
    do: empty_results_message(table_state, "No dataset rows yet.")

  defp empty_results_message(table_state, empty_message) do
    filters = Map.get(table_state, :filters, %{})
    search = Map.get(table_state, :search, "")

    if filters != %{} or search not in [nil, ""],
      do: "No results match the current filters.",
      else: empty_message
  end

  defp row_id(%{id: id}), do: id
  defp row_id(%{"id" => id}), do: id
  defp row_id(row), do: :erlang.phash2(row)

  defp column_key(column, row) do
    atom_column = existing_atom(column)

    cond do
      Map.has_key?(row, column) -> column
      atom_column && Map.has_key?(row, atom_column) -> atom_column
      true -> column
    end
  end

  defp metadata_opt(opts, key, default) when is_list(opts), do: Keyword.get(opts, key, default)

  defp metadata_opt(opts, key, default) when is_map(opts) do
    Map.get(opts, key, Map.get(opts, to_string(key), default))
  end

  defp metadata_opt(_opts, _key, default), do: default

  defp existing_atom(column) when is_binary(column) do
    String.to_existing_atom(column)
  rescue
    ArgumentError -> nil
  end

  defp existing_atom(_column), do: nil

  defp humanize(value), do: Incant.Naming.label(value)
end
