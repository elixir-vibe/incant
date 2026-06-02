defmodule Incant.Live.Routes do
  @moduledoc false

  def dashboard_path(base_path, dashboard, query_params \\ %{}) do
    path([base_path, "dashboards", module_slug(dashboard.module)], query_params)
  end

  def resource_path(base_path, resource, query_params \\ %{}) do
    path([base_path, "resources", module_slug(resource.module)], query_params)
  end

  def resource_detail_path(base_path, resource, id, query_params \\ %{}) do
    path([base_path, "resources", module_slug(resource.module), id], query_params)
  end

  def current_path(
        %{
          section: "resource",
          selected_resource: resource,
          params: params,
          base_path: base_path
        },
        query_params
      ) do
    case params["id"] do
      nil -> resource_path(base_path, resource, query_params)
      id -> resource_detail_path(base_path, resource, id, query_params)
    end
  end

  def current_path(
        %{section: "dashboard", selected_dashboard: dashboard, base_path: base_path},
        query_params
      ) do
    dashboard_path(base_path, dashboard, query_params)
  end

  def module_slug(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp path([base_path | segments], query_params) do
    suffix =
      segments
      |> Enum.map(fn segment -> URI.encode(to_string(segment), &URI.char_unreserved?/1) end)
      |> Enum.join("/")

    path = base_path <> "/" <> suffix
    query_params = reject_empty_values(query_params)

    case URI.encode_query(query_params) do
      "" -> path
      query -> path <> "?" <> query
    end
  end

  defp reject_empty_values(map) do
    Map.reject(map, fn {_key, value} -> value in [nil, "", %{}] end)
  end
end
