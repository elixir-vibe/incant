defmodule Incant.Live.AdminLive do
  @moduledoc """
  Generic LiveView renderer for an Incant admin surface.
  """

  use Phoenix.LiveView

  import Incant.Live.Components
  import Incant.Live.DashboardComponents
  import Incant.Live.ResourceComponents
  import Incant.Live.Routes

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

    section = section(params, selected_dashboard, selected_resource)
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
    <div class="min-h-screen bg-[var(--incant-bg)] text-[var(--incant-text)]">
      <aside class="fixed inset-y-0 left-0 hidden w-72 border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-5 lg:block">
        <div>
          <div class="text-xs font-semibold uppercase tracking-[0.35em] text-[var(--incant-primary)]">Incant</div>
          <div class="mt-2 text-xl font-semibold">{short_module(@admin.module)}</div>
        </div>

        <nav class="mt-8 space-y-8">
          <div>
            <div class="text-xs font-medium uppercase tracking-widest text-[var(--incant-text-muted)]">Dashboards</div>
            <div class="mt-3 space-y-1">
              <.nav_link
                :for={dashboard <- @dashboards}
                active={@section == "dashboard" and @selected_dashboard == dashboard}
                patch={dashboard_path(@base_path, dashboard)}
              >
                {dashboard.title || short_module(dashboard.module)}
              </.nav_link>
            </div>
          </div>

          <div>
            <div class="text-xs font-medium uppercase tracking-widest text-[var(--incant-text-muted)]">Resources</div>
            <div class="mt-3 space-y-1">
              <.nav_link
                :for={resource <- @resources}
                active={@section == "resource" and @selected_resource == resource}
                patch={resource_path(@base_path, resource)}
              >
                {short_module(resource.module)}
              </.nav_link>
            </div>
          </div>
        </nav>
      </aside>

      <main class="lg:pl-72">
        <div class="border-b border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-5 py-4 backdrop-blur lg:px-8">
          <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <p class="text-sm text-[var(--incant-text-muted)]">Admin surface</p>
              <h1 class="text-2xl font-semibold tracking-tight">{page_title(assigns)}</h1>
            </div>
            <div class="flex flex-wrap gap-2 text-xs text-[var(--incant-text-muted)]">
              <.pill>{length(@resources)} resources</.pill>
              <.pill>{length(@dashboards)} dashboards</.pill>
              <.pill :if={@theme}>{@theme.css_vars_prefix}</.pill>
            </div>
          </div>
        </div>

        <div class="p-5 lg:p-8">
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
        </div>
      </main>
    </div>
    """
  end

  attr(:active, :boolean, required: true)
  attr(:patch, :string, required: true)
  slot(:inner_block, required: true)

  def nav_link(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class={[
        "block rounded-lg px-3 py-2 text-sm transition",
        @active && "bg-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)] text-[var(--incant-text-highlighted)] ring-1 ring-[color-mix(in_oklab,var(--incant-primary)_35%,transparent)]",
        !@active && "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
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

  defp section(%{"resource" => _resource_param}, _dashboard, _selected_resource), do: "resource"

  defp section(%{"dashboard" => _dashboard_param}, _dashboard_metadata, _resource),
    do: "dashboard"

  defp section(_params, nil, _resource), do: "resource"
  defp section(_params, _dashboard, _resource), do: "dashboard"

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
