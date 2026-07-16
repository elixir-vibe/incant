defmodule Incant.UI.Surfaces.SectionIndex do
  @moduledoc false

  import Incant.Live.Routes

  defstruct [:id, :title, :eyebrow, items: [], regions: []]

  def from_context(%{section: "dashboards"} = context) do
    new("dashboards", "Dashboards", context.dashboards, context.base_path, &dashboard_path/2)
  end

  def from_context(%{section: "resources"} = context) do
    new("resources", "Resources", context.resources, context.base_path, &resource_path/2)
  end

  def from_context(%{section: "datasets"} = context) do
    new("datasets", "Datasets", context.datasets, context.base_path, &dataset_path/2)
  end

  defp new(id, title, surfaces, base_path, path) do
    items =
      Enum.map(surfaces, fn surface ->
        %{
          id: to_string(surface.id),
          label: surface.title,
          path: path.(base_path, surface)
        }
      end)

    %__MODULE__{id: id, title: title, eyebrow: "Section", items: items}
  end
end
