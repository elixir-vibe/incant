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
    resource_page = Incant.Live.Rows.page(selected_resource, table_state)
    resource_rows = resource_page.rows
    dashboard_variables = Map.get(params, "var", %{})
    form_mode = form_mode(socket.assigns.live_action)
    form_record = form_record(selected_resource, params["id"], form_mode)
    form_changeset = form_changeset(selected_resource, form_record, form_mode)

    selected_row = Incant.Live.Rows.one(selected_resource, params["id"])
    widget_values = widget_values(selected_dashboard, dashboard_variables)

    context = %Incant.Live.Context{
      admin: socket.assigns.admin,
      base_path: socket.assigns.base_path,
      resources: resources,
      dashboards: dashboards,
      theme: socket.assigns.theme,
      resource: selected_resource,
      dashboard: selected_dashboard,
      section: section,
      detail_id: params["id"],
      selected_row: selected_row,
      form_mode: form_mode,
      form_record: form_record,
      form_changeset: form_changeset,
      table_state: table_state,
      rows: resource_rows,
      pagination: Map.drop(resource_page, [:rows]),
      dashboard_variables: dashboard_variables,
      widget_values: widget_values
    }

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:context, context)
     |> assign(:section, section)
     |> assign(:selected_resource, selected_resource)
     |> assign(:selected_dashboard, selected_dashboard)
     |> assign(:detail_id, params["id"])
     |> assign(:selected_row, selected_row)
     |> assign(:form_mode, form_mode)
     |> assign(:form_record, form_record)
     |> assign(:form_changeset, form_changeset)
     |> assign(:table_state, table_state)
     |> assign(:resource_rows, resource_rows)
     |> assign(:widget_values, widget_values)}
  end

  @impl Phoenix.LiveView
  def handle_event("table_state", %{"table" => table_params}, socket) do
    resource = socket.assigns.selected_resource

    params =
      socket.assigns.params
      |> table_query_params()
      |> Map.merge(flatten_table_params(table_params))
      |> Map.put("page", "1")
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: resource_path(socket.assigns.base_path, resource, params))}
  end

  def handle_event("sort", %{"column" => column}, socket) do
    params =
      socket.assigns.params
      |> Map.put("sort", next_sort(socket.assigns.params["sort"], column))
      |> Map.put("page", "1")
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  def handle_event("page", %{"page" => page}, socket) do
    params =
      socket.assigns.params
      |> Map.put("page", page)
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  def handle_event("dashboard_variables", %{"var" => variables}, socket) do
    params =
      socket.assigns.params
      |> Map.put("var", variables)
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  def handle_event("row_action", %{"action" => action, "id" => id}, socket) do
    case Incant.Live.Actions.run(socket.assigns.selected_resource, action, id, socket.assigns) do
      {:ok, message} -> {:noreply, put_flash(socket, :info, message)}
      {:error, message} -> {:noreply, put_flash(socket, :error, message)}
    end
  end

  def handle_event("validate_form", %{"resource" => attrs}, socket) do
    changeset =
      Incant.Live.FormState.changeset(
        socket.assigns.selected_resource,
        socket.assigns.form_record,
        attrs
      )

    {:noreply, assign(socket, :form_changeset, changeset)}
  end

  def handle_event("save_form", %{"resource" => attrs}, socket) do
    case Incant.Live.FormState.save(
           socket.assigns.form_mode,
           socket.assigns.selected_resource,
           socket.assigns.form_record,
           attrs
         ) do
      {:ok, message, record} ->
        {:noreply,
         socket
         |> put_flash(:info, message)
         |> push_patch(
           to:
             saved_record_path(socket.assigns.base_path, socket.assigns.selected_resource, record)
         )}

      {:error, changeset} when is_map(changeset) ->
        {:noreply, assign(socket, :form_changeset, changeset)}

      {:error, message} ->
        {:noreply, put_flash(socket, :error, message)}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.admin_shell context={@context} page_title={page_title(assigns)}>
      <.dashboard_view :if={@context.section == "dashboard" and @context.dashboard} context={@context} />
      <.resource_view :if={@context.section == "resource" and @context.resource} context={@context} />
    </.admin_shell>
    """
  end

  defp widget_values(nil, _variables), do: %{}

  defp widget_values(dashboard, variables) do
    dashboard.widgets
    |> Enum.filter(&(&1.opts[:query] != nil))
    |> Map.new(fn widget ->
      {widget.id, Incant.Callback.call(widget.opts[:query], variables, nil)}
    end)
  end

  defp table_state(params) do
    %{
      search: Map.get(params, "search", ""),
      filters: Map.get(params, "filter", %{}),
      sort: Map.get(params, "sort", ""),
      page: Map.get(params, "page", "1"),
      page_size: Map.get(params, "page_size", "25")
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

  defp table_query_params(params),
    do: Map.take(params, ["search", "filter", "sort", "page", "page_size"])

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

  defp section(action, _dashboard, _resource)
       when action in [:resource, :resource_detail, :resource_new, :resource_edit],
       do: "resource"

  defp section(:dashboard, _dashboard, _resource), do: "dashboard"
  defp section(:index, nil, _resource), do: "resource"
  defp section(:index, _dashboard, _resource), do: "dashboard"

  defp form_mode(:resource_new), do: :new
  defp form_mode(:resource_edit), do: :edit
  defp form_mode(_action), do: nil

  defp saved_record_path(base_path, resource, record) do
    case Incant.Live.Rows.id(record) do
      nil -> resource_path(base_path, resource)
      id -> resource_detail_path(base_path, resource, id)
    end
  end

  defp form_record(_resource, _id, nil), do: nil
  defp form_record(resource, _id, :new), do: Incant.Forms.new_record(resource)
  defp form_record(resource, id, :edit), do: Incant.Live.Rows.one(resource, id) || %{}

  defp form_changeset(_resource, _record, nil), do: nil

  defp form_changeset(resource, record, _mode),
    do: Incant.Live.FormState.changeset(resource, record)

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
