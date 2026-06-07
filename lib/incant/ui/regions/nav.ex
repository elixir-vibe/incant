defmodule Incant.UI.Regions.Nav do
  @moduledoc """
  Admin navigation region.
  """

  alias Incant.UI.Event

  @type t :: %__MODULE__{items: [struct], active_id: String.t() | nil}

  defstruct items: [], active_id: nil

  defmodule Item do
    @moduledoc false
    @type t :: %__MODULE__{
            id: String.t(),
            label: String.t(),
            kind: atom,
            group: atom,
            event: Event.t(),
            path: String.t()
          }

    defstruct [:id, :label, :kind, :group, :event, :path]
  end

  def from_context(context) do
    dashboard_items = Enum.map(context.dashboards || [], &dashboard_item(&1, context))
    dataset_items = Enum.map(context.datasets || [], &dataset_item(&1, context))
    resource_items = Enum.map(context.resources || [], &resource_item(&1, context))

    %__MODULE__{
      items: dashboard_items ++ dataset_items ++ resource_items,
      active_id: active_id(context)
    }
  end

  defp dashboard_item(dashboard, context) do
    id = "dashboard.#{dashboard.module}"

    %Item{
      id: id,
      label: dashboard.title || short_module(dashboard.module),
      kind: :dashboard,
      group: :dashboards,
      event: %Event{op: :navigate, surface: "dashboard", target: id},
      path: Incant.Live.Routes.dashboard_path(context.base_path, dashboard)
    }
  end

  defp dataset_item(dataset, context) do
    id = "dataset.#{dataset.module}"

    %Item{
      id: id,
      label: dataset.title || short_module(dataset.module),
      kind: :dataset,
      group: :datasets,
      event: %Event{op: :navigate, surface: "dataset", target: id},
      path: Incant.Live.Routes.dataset_path(context.base_path, dataset)
    }
  end

  defp resource_item(resource, context) do
    id = "resource.#{resource.module}"

    %Item{
      id: id,
      label: short_module(resource.module),
      kind: :resource,
      group: :resources,
      event: %Event{op: :navigate, surface: "resource", target: id},
      path: Incant.Live.Routes.resource_path(context.base_path, resource)
    }
  end

  defp active_id(%{section: "dashboard", dashboard: %{module: module}}), do: "dashboard.#{module}"
  defp active_id(%{section: "dataset", dataset: %{module: module}}), do: "dataset.#{module}"
  defp active_id(%{section: "resource", resource: %{module: module}}), do: "resource.#{module}"
  defp active_id(_context), do: nil

  defp short_module(module), do: module |> Module.split() |> List.last()
end
