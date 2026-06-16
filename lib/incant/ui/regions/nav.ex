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
    id = "dashboard.#{surface_id(dashboard)}"

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
    id = "dataset.#{surface_id(dataset)}"

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
    id = "resource.#{resource.id}"

    %Item{
      id: id,
      label: surface_title(resource),
      kind: :resource,
      group: :resources,
      event: %Event{op: :navigate, surface: "resource", target: id},
      path: Incant.Live.Routes.resource_path(context.base_path, resource)
    }
  end

  defp active_id(%{section: "dashboard", dashboard: dashboard}),
    do: "dashboard.#{surface_id(dashboard)}"

  defp active_id(%{section: "dataset", dataset: dataset}), do: "dataset.#{surface_id(dataset)}"

  defp active_id(%{section: "resource", resource: resource}), do: "resource.#{resource.id}"
  defp active_id(_context), do: nil

  defp surface_id(%{id: id}), do: id
  defp surface_id(surface), do: Incant.Surface.id(surface.module, surface.opts)

  defp surface_title(%{title: title}) when not is_nil(title), do: title
  defp surface_title(surface), do: Incant.Surface.title(surface.module, surface.opts)

  defp short_module(module) when is_atom(module), do: module |> Module.split() |> List.last()
  defp short_module(module), do: module |> to_string() |> String.split(".") |> List.last()
end
