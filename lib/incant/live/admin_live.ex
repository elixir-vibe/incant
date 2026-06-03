defmodule Incant.Live.AdminLive do
  @moduledoc """
  Generic LiveView renderer for an Incant admin surface.
  """

  use Phoenix.LiveView

  import Incant.Live.Routes

  alias Incant.Live.{Authorization, Dashboard, Resource, Shell}

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
      |> assign(:actor, Authorization.actor(socket.assigns, admin))

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
    dashboard_variables = Map.get(params, "var", %{})
    form_mode = form_mode(socket.assigns.live_action)
    actor_context = %{admin: socket.assigns.admin, actor: socket.assigns.actor}
    selected_row = Incant.Live.Rows.one(selected_resource, params["id"], actor_context)
    form_record = form_record(selected_resource, params["id"], form_mode, actor_context)
    form_changeset = form_changeset(selected_resource, form_record, form_mode)

    context =
      %Incant.Live.Context{
        admin: socket.assigns.admin,
        base_path: socket.assigns.base_path,
        resources: resources,
        dashboards: dashboards,
        theme: socket.assigns.theme,
        actor: socket.assigns.actor,
        resource: selected_resource,
        dashboard: selected_dashboard,
        section: section,
        detail_id: params["id"],
        selected_row: selected_row,
        form_mode: form_mode,
        form_record: form_record,
        form_changeset: form_changeset,
        table_state: table_state,
        dashboard_variables: dashboard_variables
      }
      |> authorize_context(socket.assigns.admin)
      |> load_authorized_context()

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:context, context)}
  end

  @impl Phoenix.LiveView
  def handle_event("table_state", %{"table" => table_params}, socket) do
    resource = socket.assigns.context.resource

    params =
      socket.assigns.params
      |> table_query_params()
      |> Map.merge(flatten_table_params(table_params))
      |> Map.put("page", "1")
      |> reject_empty_values()

    {:noreply,
     push_patch(socket, to: resource_path(socket.assigns.context.base_path, resource, params))}
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
    context = socket.assigns.context
    row = Incant.Live.Rows.one(context.resource, id, context)

    with :ok <- authorize(context, :run_action, %{action: action, row: row}) do
      case Incant.Live.Actions.run(context.resource, action, id, socket.assigns) do
        {:ok, message} -> {:noreply, put_flash(socket, :info, message)}
        {:error, message} -> {:noreply, put_flash(socket, :error, message)}
      end
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  def handle_event("validate_form", %{"resource" => attrs}, socket) do
    context = socket.assigns.context

    with :ok <- authorize(context, form_action(context)) do
      changeset =
        Incant.Live.FormState.validate(
          context.resource,
          context.form_record,
          attrs
        )

      {:noreply, assign_context(socket, :form_changeset, changeset)}
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  def handle_event("save_form", %{"resource" => attrs}, socket) do
    context = socket.assigns.context

    with :ok <- authorize(context, form_action(context)) do
      case Incant.Live.FormState.save(
             context.form_mode,
             context.resource,
             context.form_record,
             attrs
           ) do
        {:ok, message, record} ->
          {:noreply,
           socket
           |> put_flash(:info, message)
           |> push_patch(
             to:
               saved_record_path(
                 context.base_path,
                 context.resource,
                 record
               )
           )}

        {:error, changeset} when is_map(changeset) ->
          {:noreply, assign_context(socket, :form_changeset, changeset)}

        {:error, message} ->
          {:noreply, put_flash(socket, :error, message)}
      end
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <Shell.view context={@context} page_title={page_title(@context)}>
      <.access_denied :if={match?({:error, _reason}, @context.authorization)} context={@context} />
      <Dashboard.view :if={@context.authorization == :ok and @context.section == "dashboard" and @context.dashboard} context={@context} />
      <Resource.view :if={@context.authorization == :ok and @context.section == "resource" and @context.resource} context={@context} />
    </Shell.view>
    """
  end

  def access_denied(assigns) do
    ~H"""
    <section class="rounded-2xl border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-8 text-center shadow-sm">
      <p class="text-sm text-[var(--incant-text-muted)]">Access denied</p>
      <h2 class="mt-2 text-2xl font-semibold tracking-tight">You are not authorized to view this admin area.</h2>
    </section>
    """
  end

  defp assign_context(socket, key, value) do
    assign(socket, :context, Map.put(socket.assigns.context, key, value))
  end

  defp authorize_context(context, admin) do
    authorization =
      with :ok <-
             Authorization.authorize(admin, :view_admin, context.actor, Map.from_struct(context)),
           :ok <-
             Authorization.authorize(
               admin,
               view_action(context),
               context.actor,
               Map.from_struct(context)
             ),
           :ok <- authorize_form_navigation(admin, context) do
        :ok
      end

    %{context | authorization: authorization}
  end

  defp load_authorized_context(%{authorization: :ok, section: "resource"} = context) do
    resource_page = Incant.Live.Rows.page(context.resource, context.table_state, context)

    %{context | rows: resource_page.rows, pagination: Map.drop(resource_page, [:rows])}
  end

  defp load_authorized_context(%{authorization: :ok, section: "dashboard"} = context) do
    %{context | widget_values: widget_values(context.dashboard, context.dashboard_variables)}
  end

  defp load_authorized_context(context), do: context

  defp authorize(context, action, extra \\ %{}) do
    Authorization.authorize(
      context.admin,
      action,
      context.actor,
      context |> Map.from_struct() |> Map.merge(extra)
    )
  end

  defp authorize_form_navigation(_admin, %{form_mode: nil}), do: :ok

  defp authorize_form_navigation(admin, context) do
    Authorization.authorize(admin, form_action(context), context.actor, Map.from_struct(context))
  end

  defp view_action(%{section: "dashboard"}), do: :view_dashboard
  defp view_action(%{section: "resource"}), do: :view_resource
  defp view_action(_context), do: :view_admin

  defp form_action(%{form_mode: :new}), do: :create
  defp form_action(%{form_mode: :edit}), do: :edit
  defp form_action(_context), do: :view_resource

  defp authorization_message(:unauthorized), do: "You are not authorized to perform this action."
  defp authorization_message(reason), do: to_string(reason)

  defp widget_values(nil, _variables), do: %{}

  defp widget_values(dashboard, variables) do
    dashboard.widgets
    |> Enum.filter(&(&1.opts[:query] != nil))
    |> Map.new(fn widget ->
      value =
        try do
          Incant.Callback.call(widget.opts[:query], variables, nil)
        rescue
          error -> {:error, Exception.message(error)}
        catch
          kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
        end

      {widget.id, value}
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
    |> Map.put("page_size", Map.get(table_params, "page_size"))
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

  defp form_record(_resource, _id, nil, _context), do: nil
  defp form_record(resource, _id, :new, _context), do: Incant.Forms.new_record(resource)

  defp form_record(resource, id, :edit, context),
    do: Incant.Live.Rows.one(resource, id, context) || %{}

  defp form_changeset(_resource, _record, nil), do: nil

  defp form_changeset(resource, record, _mode),
    do: Incant.Live.FormState.changeset(resource, record)

  defp page_title(%{section: "resource", resource: resource})
       when not is_nil(resource) do
    short_module(resource.module)
  end

  defp page_title(%{section: "dashboard", dashboard: dashboard})
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
