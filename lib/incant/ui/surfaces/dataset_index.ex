defmodule Incant.UI.Surfaces.DatasetIndex do
  @moduledoc """
  Dataset table surface.
  """

  alias Incant.UI.Regions.{FilterBar, Table}

  defstruct [:id, :title, :dataset, :filter_bar, :table, regions: []]

  def from_context(context, title) do
    filter_bar = FilterBar.from_dataset_context(context)
    table = Table.from_dataset_context(context)

    %__MODULE__{
      id: "dataset.index",
      title: title,
      dataset: context.dataset,
      filter_bar: filter_bar,
      table: table,
      regions: Enum.reject([filter_bar, table], &is_nil/1)
    }
  end
end
