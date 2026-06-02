defmodule Incant.Live.AdminLive do
  @moduledoc """
  Generic LiveView renderer for an Incant admin surface.
  """

  use Phoenix.LiveView

  import Incant.Live.DashboardComponents
  import Incant.Live.ResourceComponents
  import Incant.Live.Routes
  import Incant.Live.ShellComponents

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    admin_module = Map.fetch!(session, "admin")
    admin = Incant.metadata(admin_module)

    socket =
      socket
      |> assign(:base_path, Map.get(session, "base_path", "/admin"))
      |> assign(:admin, admin)
      |> assign(:resources, Enum.map(admin.resources, &Incant.metadata/1))
      |> assign(:dashboards, Enum.map(admin.dashboards, &Incant.metadata/1))
      |> assign(:theme, theme_metadata(admin))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    resources = socket.assigns.resources
    dashboards = socket.assigns.dashboards

    selected_resource = select_by_module(resources, params["resource"]) || List.first(resources)

    selected_dashboard =
      select_by_module(dashboards, params["dashboard"]) || List.first(dashboards)

    section = section(socket.assigns.live_action, selected_dashboard, selected_resource)
    table_state = table_state(params)
    resource_rows = Incant.Live.Rows.list(selected_resource, table_state)

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:section, section)
     |> assign(:selected_resource, selected_resource)
     |> assign(:selected_dashboard, selected_dashboard)
     |> assign(:detail_id, params["id"])
     |> assign(:selected_row, Incant.Live.Rows.one(selected_resource, params["id"]))
     |> assign(:table_state, table_state)
     |> assign(:resource_rows, resource_rows)
     |> assign(:widget_values, widget_values(selected_dashboard))}
  end

  @impl Phoenix.LiveView
  def handle_event("table_state", %{"table" => table_params}, socket) do
    resource = socket.assigns.selected_resource

    params =
      socket.assigns.params
      |> table_query_params()
      |> Map.merge(flatten_table_params(table_params))
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: resource_path(socket.assigns.base_path, resource, params))}
  end

  def handle_event("sort", %{"column" => column}, socket) do
    params =
      socket.assigns.params
      |> Map.put("sort", next_sort(socket.assigns.params["sort"], column))
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.admin_shell
      admin={@admin}
      resources={@resources}
      dashboards={@dashboards}
      theme={@theme}
      section={@section}
      selected_resource={@selected_resource}
      selected_dashboard={@selected_dashboard}
      base_path={@base_path}
      page_title={page_title(assigns)}
    >
      <.dashboard_view
        :if={@section == "dashboard" and @selected_dashboard}
        dashboard={@selected_dashboard}
        widget_values={@widget_values}
      />
      <.resource_view
        :if={@section == "resource" and @selected_resource}
        resource={@selected_resource}
        rows={@resource_rows}
        selected_row={@selected_row}
        detail_id={@detail_id}
        base_path={@base_path}
        table_state={@table_state}
      />
    </.admin_shell>
    """
  end

  defp widget_values(nil), do: %{}

  defp widget_values(dashboard) do
    dashboard.widgets
    |> Enum.filter(&(&1.opts[:query] != nil))
    |> Map.new(fn widget -> {widget.id, Incant.Callback.call(widget.opts[:query], %{}, nil)} end)
  end

  defp table_state(params) do
    %{
      search: Map.get(params, "search", ""),
      filters: Map.get(params, "filter", %{}),
      sort: Map.get(params, "sort", "")
    }
  end

  defp flatten_table_params(table_params) do
    filters = Map.get(table_params, "filters", %{}) |> reject_empty_values()

    %{}
    |> Map.put("search", Map.get(table_params, "search"))
    |> Map.put("filter", filters)
  end

  defp reject_empty_values(map) do
    Map.reject(map, fn {_key, value} -> value in [nil, "", %{}] end)
  end

  defp table_query_params(params), do: Map.take(params, ["search", "filter", "sort"])

  defp next_sort(current_sort, column) do
    case current_sort do
      ^column -> "-#{column}"
      "-" <> ^column -> ""
      _other -> column
    end
  end

  defp theme_metadata(admin) do
    case admin.opts[:theme] do
      nil -> nil
      module -> Incant.metadata(module)
    end
  end

  defp select_by_module(collection, nil), do: List.first(collection)

  defp select_by_module(collection, module_id) do
    Enum.find(collection, &(module_slug(&1.module) == module_id))
  end

  defp section(action, _dashboard, _resource) when action in [:resource, :resource_detail],
    do: "resource"

  defp section(:dashboard, _dashboard, _resource), do: "dashboard"
  defp section(:index, nil, _resource), do: "resource"
  defp section(:index, _dashboard, _resource), do: "dashboard"

  defp page_title(%{section: "resource", selected_resource: resource})
       when not is_nil(resource) do
    short_module(resource.module)
  end

  defp page_title(%{section: "dashboard", selected_dashboard: dashboard})
       when not is_nil(dashboard) do
    dashboard.title || short_module(dashboard.module)
  end

  defp page_title(_assigns), do: "Incant"

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
