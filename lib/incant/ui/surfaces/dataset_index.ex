defmodule Incant.UI.Surfaces.DatasetIndex do
  @moduledoc """
  Dataset table surface.
  """

  alias Incant.UI.Regions.{FilterBar, Table}

  defstruct [:id, :title, :dataset, :filter_bar, :table, drilldowns: [], regions: []]

  def from_context(context, title) do
    filter_bar = FilterBar.from_dataset_context(context)
    table = Table.from_dataset_context(context)

    %__MODULE__{
      id: "dataset.index",
      title: title,
      dataset: context.dataset,
      filter_bar: filter_bar,
      table: table,
      drilldowns: drilldowns(context),
      regions: Enum.reject([filter_bar, table], &is_nil/1)
    }
  end

  defp drilldowns(context) do
    Enum.map(context.dataset.table.drilldowns, fn drilldown ->
      active =
        to_string(Map.get(context.table_state, :drilldown, "")) == to_string(drilldown.dimension)

      %{
        id: to_string(drilldown.dimension),
        label: drilldown.opts[:label] || humanize(drilldown.dimension),
        active: active,
        path:
          Incant.Live.Routes.dataset_path(context.base_path, context.dataset, %{
            "filter" => context.table_state.filters,
            "drilldown" => drilldown.dimension,
            "page_size" => context.table_state.page_size
          })
      }
    end)
  end

  defp humanize(value), do: Incant.Naming.label(value)
end
