defmodule Incant.UI.Surfaces.DatasetIndex do
  @moduledoc """
  Dataset table surface.
  """

  alias Incant.UI.Regions.Table

  defstruct [:id, :title, :dataset, :table, regions: []]

  def from_context(context, title) do
    table = Table.from_dataset_context(context)

    %__MODULE__{
      id: "dataset.index",
      title: title,
      dataset: context.dataset,
      table: table,
      regions: [table]
    }
  end
end
