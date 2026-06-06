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
    defstruct [:id, cells: [], actions: [], event: nil, source: nil]
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
      empty_state: "No rows. Add a resource data callback or loosen the current filters.",
      density: resource.table.opts[:density] || :compact
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
      source: record
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

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
