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
    defstruct [:id, cells: [], actions: [], detail: nil, event: nil, source: nil]
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
    rows = Enum.map(context.rows || [], &row_from_record(&1, resource))

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
      empty_state: "No rows. Add a resource data callback or loosen the current filters.",
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
      empty_state: dataset_empty_state(result),
      density: context.dataset.table.opts[:density] || :compact
    }
  end

  defp column_from_metadata(column) do
    %Column{
      id: to_string(column.name),
      label: column.opts[:label] || humanize(column.name),
      align: column.opts[:align],
      sortable: true,
      format: column.opts[:format],
      width: column.opts[:width],
      priority: column.opts[:priority],
      source: column
    }
  end

  defp row_from_record(record, resource) do
    %Row{
      id: Incant.Live.Rows.id(record),
      cells: Enum.map(resource.table.columns, &cell_from_record(record, &1)),
      actions: resource.table.actions,
      detail: row_detail_from_metadata(resource.table.row_detail),
      source: record
    }
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

  defp selection_from_metadata(table, selected_ids) do
    %Selection{
      enabled: table.bulk_actions != [],
      selected_ids: Enum.map(selected_ids, &to_string/1)
    }
  end

  defp cell_from_record(record, column) do
    value = Incant.Live.Rows.field(record, column.name)

    %Cell{
      column: to_string(column.name),
      value: value,
      display: Incant.Live.Format.value(value, column.opts[:format]),
      tone: column.opts[:tone],
      format: column.opts[:as] || column.opts[:format],
      source: column
    }
  end

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

  defp result_columns(dataset, %{columns: []}), do: dataset.table.columns
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

  defp dataset_empty_state(%{meta: %{error: reason}}),
    do: "Dataset query failed: #{inspect(reason)}"

  defp dataset_empty_state(_result), do: "No rows match the current dataset query."

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

  defp existing_atom(column) when is_binary(column) do
    String.to_existing_atom(column)
  rescue
    ArgumentError -> nil
  end

  defp existing_atom(_column), do: nil

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
