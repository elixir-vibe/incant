defmodule Incant.UI.Regions.Nav do
  @moduledoc """
  Admin navigation region.
  """

  alias Incant.UI.Event

  @type t :: %__MODULE__{items: [map], active_id: String.t() | nil}

  defstruct items: [], active_id: nil

  def from_context(context) do
    dashboard_items = Enum.map(context.dashboards || [], &dashboard_item(&1, context))
    resource_items = Enum.map(context.resources || [], &resource_item(&1, context))

    %__MODULE__{items: dashboard_items ++ resource_items, active_id: active_id(context)}
  end

  defp dashboard_item(dashboard, context) do
    id = "dashboard.#{dashboard.module}"

    %{
      id: id,
      label: dashboard.title || short_module(dashboard.module),
      kind: :dashboard,
      group: :dashboards,
      event: %Event{op: :navigate, surface: "dashboard", target: id},
      path: Incant.Live.Routes.dashboard_path(context.base_path, dashboard)
    }
  end

  defp resource_item(resource, context) do
    id = "resource.#{resource.module}"

    %{
      id: id,
      label: short_module(resource.module),
      kind: :resource,
      group: :resources,
      event: %Event{op: :navigate, surface: "resource", target: id},
      path: Incant.Live.Routes.resource_path(context.base_path, resource)
    }
  end

  defp active_id(%{section: "dashboard", dashboard: %{module: module}}), do: "dashboard.#{module}"
  defp active_id(%{section: "resource", resource: %{module: module}}), do: "resource.#{module}"
  defp active_id(_context), do: nil

  defp short_module(module), do: module |> Module.split() |> List.last()
end
