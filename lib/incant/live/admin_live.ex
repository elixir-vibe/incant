defmodule Incant.Live.AdminLive do
  @moduledoc """
  Generic LiveView renderer for an Incant admin surface.
  """

  use Phoenix.LiveView

  import Incant.Live.Routes

  alias Incant.Live.Authorization

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    admin_module = Map.fetch!(session, "admin")
    admin = Incant.metadata(admin_module)

    socket =
      socket
      |> assign(:base_path, Map.get(session, "base_path", "/admin"))
      |> assign(:admin, admin)
      |> assign(:resources, admin |> Incant.Admin.resources() |> Enum.map(& &1.spec))
      |> assign(:dashboards, Enum.map(admin.dashboards, &Incant.metadata/1))
      |> assign(:datasets, Enum.map(admin.datasets, &Incant.metadata/1))
      |> assign(:theme, theme_metadata(admin))
      |> assign(:actor, Authorization.actor(socket.assigns, admin))

    {:ok, socket}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _uri, socket) do
    resources = socket.assigns.resources
    dashboards = socket.assigns.dashboards
    datasets = socket.assigns.datasets

    visible_resources =
      filter_authorized(resources, socket.assigns.admin, socket.assigns.actor, :view_resource)

    visible_dashboards =
      filter_authorized(dashboards, socket.assigns.admin, socket.assigns.actor, :view_dashboard)

    visible_datasets =
      filter_authorized(datasets, socket.assigns.admin, socket.assigns.actor, :view_dataset)

    selected_resource =
      select_by_id(resources, params["resource"]) || List.first(visible_resources)

    selected_dashboard =
      select_by_id(dashboards, params["dashboard"]) || List.first(visible_dashboards)

    selected_dataset =
      select_by_id(datasets, params["dataset"]) || List.first(visible_datasets)

    section =
      section(socket.assigns.live_action, selected_dashboard, selected_resource, selected_dataset)

    table_state = table_state(params)

    raw_dashboard_variables = Map.get(params, "var", %{})
    dashboard_variables = cast_dashboard_variables(selected_dashboard, raw_dashboard_variables)
    form_mode = form_mode(socket.assigns.live_action)

    context =
      %Incant.Live.Context{
        admin: socket.assigns.admin,
        base_path: socket.assigns.base_path,
        resources: visible_resources,
        dashboards: visible_dashboards,
        datasets: visible_datasets,
        theme: socket.assigns.theme,
        actor: socket.assigns.actor,
        resource: selected_resource,
        dashboard: selected_dashboard,
        dataset: selected_dataset,
        section: section,
        detail_id: params["id"],
        form_mode: form_mode,
        table_state: table_state,
        dashboard_variables: dashboard_variables,
        raw_dashboard_variables: raw_dashboard_variables
      }
      |> authorize_surface(socket.assigns.admin)
      |> load_authorized_context()
      |> authorize_loaded_context(socket.assigns.admin)

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:context, context)}
  end

  @impl Phoenix.LiveView
  def handle_event("incant:event", params, socket) do
    params
    |> Incant.UI.Event.parse()
    |> handle_incant_event(socket)
  end

  defp handle_incant_event(%{op: :filter_commit} = event, socket),
    do: filter_commit(event, socket)

  defp handle_incant_event(%{op: :dashboard_variable_commit} = event, socket),
    do: dashboard_variable_commit(event, socket)

  defp handle_incant_event(%{op: :sort} = event, socket), do: sort(event, socket)
  defp handle_incant_event(%{op: :paginate} = event, socket), do: paginate(event, socket)
  defp handle_incant_event(%{op: :row_select} = event, socket), do: row_select(event, socket)
  defp handle_incant_event(%{op: :row_action} = event, socket), do: row_action(event, socket)
  defp handle_incant_event(%{op: :bulk_action} = event, socket), do: bulk_action(event, socket)
  defp handle_incant_event(%{op: :page_action} = event, socket), do: page_action(event, socket)

  defp handle_incant_event(%{op: :form_validate} = event, socket),
    do: form_validate(event, socket)

  defp handle_incant_event(%{op: :form_submit} = event, socket), do: form_submit(event, socket)
  defp handle_incant_event(_event, socket), do: {:noreply, socket}

  defp filter_commit(%{meta: %{"table" => table_params}}, socket) do
    params =
      socket.assigns.params
      |> table_query_params()
      |> Map.merge(flatten_table_params(table_params))
      |> Map.put("page", "1")
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  defp dashboard_variable_commit(%{meta: %{"var" => variables}}, socket) do
    params =
      socket.assigns.params
      |> Map.put("var", variables)
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  defp sort(%{target: column}, socket) do
    params =
      socket.assigns.params
      |> Map.put("sort", next_sort(socket.assigns.params["sort"], column))
      |> Map.put("page", "1")
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  defp paginate(%{value: page}, socket) do
    params =
      socket.assigns.params
      |> Map.put("page", page)
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  defp row_select(%{value: id}, socket) do
    selected_ids = toggle_selected(socket.assigns.context.table_state.selected_ids, id)

    params =
      socket.assigns.params
      |> table_query_params()
      |> Map.put("selected", Enum.join(selected_ids, ","))
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: current_path(socket.assigns, params))}
  end

  defp row_action(%{target: action, value: id}, socket) do
    context = socket.assigns.context
    row = Incant.Live.Rows.one(context.resource, id, context)

    with :ok <- authorize(context, :run_action, %{action: action, row: row}) do
      action_result(socket, Incant.Live.Actions.run(context.resource, action, id, socket.assigns))
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  defp bulk_action(%{target: action}, socket) do
    context = socket.assigns.context
    selected_ids = context.table_state.selected_ids

    with false <- selected_ids == [],
         :ok <- authorize(context, :run_action, %{action: action, selected_ids: selected_ids}) do
      action_result(
        socket,
        Incant.Live.Actions.run_bulk(context.resource, action, selected_ids, socket.assigns)
      )
    else
      true -> {:noreply, put_flash(socket, :error, "Select rows before running a bulk action")}
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  defp page_action(%{target: action}, socket) do
    context = socket.assigns.context

    with :ok <- authorize(context, :run_action, %{action: action}) do
      action_result(
        socket,
        Incant.Live.Actions.run_page(context.resource, action, socket.assigns)
      )
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  defp action_result(socket, %Incant.ActionResult.Toast{level: level, message: message}) do
    {:noreply, put_flash(socket, flash_level(level), message)}
  end

  defp action_result(socket, %Incant.ActionResult.Error{message: message}) do
    {:noreply, put_flash(socket, :error, message)}
  end

  defp action_result(socket, %Incant.ActionResult.Refresh{}) do
    {:noreply, push_patch(socket, to: current_path(socket.assigns, socket.assigns.params))}
  end

  defp action_result(socket, %Incant.ActionResult.Navigate{to: to, mode: :navigate}) do
    {:noreply, push_navigate(socket, to: to)}
  end

  defp action_result(socket, %Incant.ActionResult.Navigate{to: to}) do
    {:noreply, push_patch(socket, to: to)}
  end

  defp action_result(socket, %Incant.ActionResult.Download{label: label}) do
    {:noreply, put_flash(socket, :info, label || "Download is ready")}
  end

  defp action_result(socket, %Incant.ActionResult.Job{label: label}) do
    {:noreply, put_flash(socket, :info, label || "Background job started")}
  end

  defp action_result(socket, %Incant.ActionResult.OpenSurface{}) do
    {:noreply, put_flash(socket, :info, "Action surface is ready")}
  end

  defp action_result(socket, {:error, message}),
    do: {:noreply, put_flash(socket, :error, message)}

  defp flash_level(level) when level in [:info, :error], do: level
  defp flash_level(:warning), do: :error
  defp flash_level(_level), do: :info

  defp form_validate(%{meta: %{"resource" => attrs}}, socket) do
    context = socket.assigns.context

    with :ok <- authorize_form(context, attrs) do
      changeset = Incant.Live.FormState.validate(context.resource, context.form_record, attrs)
      {:noreply, assign_context(socket, :form_changeset, changeset)}
    else
      {:error, reason} -> {:noreply, put_flash(socket, :error, authorization_message(reason))}
    end
  end

  defp form_submit(%{meta: %{"resource" => attrs}}, socket) do
    context = socket.assigns.context

    with :ok <- authorize_form(context, attrs) do
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
           |> push_patch(to: saved_record_path(context.base_path, context.resource, record))}

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
    assigns =
      assigns
      |> assign(
        :ui_document,
        Incant.UI.Document.from_context(assigns.context, page_title: page_title(assigns.context))
      )
      |> assign(:ui_env, Incant.UI.Env.new(assigns.context, assigns))

    ~H"""
    <%= Incant.UI.render(@ui_document, @ui_env) %>
    """
  end

  def access_denied(assigns) do
    assigns = assign(assigns, :message, denied_message(assigns.context.authorization))

    ~H"""
    <section class="rounded-2xl border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-8 text-center shadow-sm">
      <p class="text-sm text-[var(--incant-text-muted)]">Access denied</p>
      <h2 class="mt-2 text-2xl font-semibold tracking-tight">{@message}</h2>
    </section>
    """
  end

  defp filter_authorized(items, admin, actor, action) do
    Enum.filter(items, fn item ->
      context = authorization_item_context(action, item)
      Authorization.allowed?(admin, action, actor, context)
    end)
  end

  defp authorization_item_context(:view_resource, resource), do: %{resource: resource}
  defp authorization_item_context(:view_dashboard, dashboard), do: %{dashboard: dashboard}
  defp authorization_item_context(:view_dataset, dataset), do: %{dataset: dataset}

  defp assign_context(socket, key, value) do
    assign(socket, :context, Map.put(socket.assigns.context, key, value))
  end

  defp authorize_surface(context, admin) do
    authorization =
      with :ok <-
             Authorization.authorize(admin, :view_admin, context.actor, Map.from_struct(context)),
           :ok <-
             Authorization.authorize(
               admin,
               view_action(context),
               context.actor,
               Map.from_struct(context)
             ) do
        :ok
      end

    %{context | authorization: authorization}
  end

  defp load_authorized_context(%{authorization: :ok, section: "resource"} = context) do
    resource_page = Incant.Live.Rows.page(context.resource, context.table_state, context)
    selected_row = Incant.Live.Rows.one(context.resource, context.detail_id, context)
    form_record = form_record(context.resource, context.detail_id, context.form_mode, context)
    form_changeset = form_changeset(context.resource, form_record, context.form_mode)

    %{
      context
      | rows: resource_page.rows,
        pagination: Map.drop(resource_page, [:rows]),
        selected_row: selected_row,
        form_record: form_record,
        form_changeset: form_changeset
    }
  end

  defp load_authorized_context(%{authorization: :ok, section: "dashboard"} = context) do
    %{
      context
      | widget_values:
          widget_values(
            context.dashboard,
            context.dashboard_variables,
            context.raw_dashboard_variables
          )
    }
  end

  defp load_authorized_context(
         %{authorization: :ok, section: "dataset", dataset: dataset} = context
       )
       when not is_nil(dataset) do
    dataset_result =
      case Incant.Dataset.run(context.dataset, dataset_query_opts(context)) do
        {:ok, result} -> result
        {:error, reason} -> %Incant.Result{meta: %{error: reason}}
      end

    %{context | dataset_result: dataset_result}
  end

  defp load_authorized_context(context), do: context

  defp authorize_loaded_context(%{authorization: :ok} = context, admin) do
    authorization =
      with :ok <- authorize_row_navigation(admin, context),
           :ok <- authorize_form_navigation(admin, context) do
        :ok
      end

    %{context | authorization: authorization}
  end

  defp authorize_loaded_context(context, _admin), do: context

  defp authorize(context, action, extra) do
    Authorization.authorize(
      context.admin,
      action,
      context.actor,
      context |> Map.from_struct() |> Map.merge(extra)
    )
  end

  defp authorize_row_navigation(_admin, %{detail_id: nil}), do: :ok

  defp authorize_row_navigation(admin, %{section: "resource"} = context) do
    case Authorization.authorize(admin, :view_row, context.actor, Map.from_struct(context)) do
      :ok -> :ok
      {:error, _reason} -> {:error, :not_found}
    end
  end

  defp authorize_row_navigation(_admin, _context), do: :ok

  defp authorize_form_navigation(_admin, %{form_mode: nil}), do: :ok

  defp authorize_form_navigation(admin, context) do
    Authorization.authorize(
      admin,
      form_action(context),
      context.actor,
      form_context(context, %{})
    )
  end

  defp authorize_form(context, attrs) do
    Authorization.authorize(
      context.admin,
      form_action(context),
      context.actor,
      form_context(context, %{attrs: attrs})
    )
  end

  defp form_context(context, extra) do
    context
    |> Map.from_struct()
    |> Map.put(:row, context.selected_row || context.form_record)
    |> Map.merge(extra)
  end

  defp view_action(%{section: "dashboard"}), do: :view_dashboard
  defp view_action(%{section: "dataset"}), do: :view_dataset
  defp view_action(%{section: "resource"}), do: :view_resource
  defp view_action(_context), do: :view_admin

  defp form_action(%{form_mode: :new}), do: :create
  defp form_action(%{form_mode: :edit}), do: :edit
  defp form_action(_context), do: :view_resource

  defp denied_message({:error, :not_found}), do: "Record not found or unavailable."
  defp denied_message(_authorization), do: "You are not authorized to view this admin area."

  defp authorization_message(:unauthorized), do: "You are not authorized to perform this action."
  defp authorization_message(:not_found), do: "Record not found or unavailable."
  defp authorization_message(reason), do: to_string(reason)

  defp widget_values(nil, _variables, _raw_variables), do: %{}

  defp widget_values(dashboard, variables, raw_variables) do
    dashboard.widgets
    |> Enum.filter(&(&1.opts[:query] != nil))
    |> Map.new(fn widget ->
      value =
        try do
          Incant.Callback.call(widget.opts[:query], variables, %{
            variables: variables,
            raw_variables: raw_variables
          })
        rescue
          error in [ArgumentError, FunctionClauseError, UndefinedFunctionError, RuntimeError] ->
            {:error, Exception.message(error)}
        catch
          kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
        end

      {widget.id, value}
    end)
  end

  defp cast_dashboard_variables(nil, variables), do: variables

  defp cast_dashboard_variables(dashboard, variables) do
    Map.new(dashboard.variables, fn variable ->
      key = to_string(variable.name)
      value = Map.get(variables, key, variable.opts[:default])
      {key, cast_dashboard_variable(variable, value)}
    end)
    |> Map.merge(Map.drop(variables, Enum.map(dashboard.variables, &to_string(&1.name))))
    |> reject_empty_values()
  end

  defp cast_dashboard_variable(%{type: :multi_select}, nil), do: []
  defp cast_dashboard_variable(%{type: :multi_select}, values) when is_list(values), do: values
  defp cast_dashboard_variable(%{type: :multi_select}, value), do: [value]

  defp cast_dashboard_variable(%{type: :date_range}, value) when is_map(value) do
    value
    |> Map.take(["from", "to"])
    |> Map.new(fn {key, value} -> {key, cast_date(value)} end)
    |> reject_empty_values()
  end

  defp cast_dashboard_variable(%{type: :date}, value), do: cast_date(value)
  defp cast_dashboard_variable(_variable, value), do: value

  defp cast_date(%Date{} = date), do: date

  defp cast_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _error -> value
    end
  end

  defp cast_date(value), do: value

  defp table_state(params) do
    %{
      search: Map.get(params, "search", ""),
      filters: Map.get(params, "filter", %{}),
      drilldown: Map.get(params, "drilldown"),
      sort: Map.get(params, "sort", ""),
      page: Map.get(params, "page", "1"),
      page_size: Map.get(params, "page_size", "25"),
      selected_ids: selected_ids(Map.get(params, "selected", ""))
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
    do:
      Map.take(params, ["search", "filter", "drilldown", "sort", "page", "page_size", "selected"])

  defp toggle_selected(selected_ids, id) do
    id = to_string(id)

    if id in selected_ids do
      Enum.reject(selected_ids, &(&1 == id))
    else
      selected_ids ++ [id]
    end
  end

  defp selected_ids(nil), do: []
  defp selected_ids(""), do: []
  defp selected_ids(ids) when is_list(ids), do: Enum.map(ids, &to_string/1)

  defp selected_ids(ids) when is_binary(ids) do
    ids
    |> String.split(",", trim: true)
    |> Enum.uniq()
  end

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

  defp dataset_query_opts(context) do
    [
      filters: context.table_state.filters,
      drilldown: context.table_state.drilldown,
      page: Incant.Params.positive_integer(context.table_state.page, 1),
      page_size: Incant.Params.positive_integer(context.table_state.page_size, 25),
      context: context
    ]
  end

  defp select_by_id(collection, nil), do: List.first(collection)

  defp select_by_id(collection, id) do
    Enum.find(collection, &(selected_id(&1) == id))
  end

  defp section(action, _dashboard, _resource, _dataset)
       when action in [:resource, :resource_detail, :resource_new, :resource_edit],
       do: "resource"

  defp section(:dashboard, _dashboard, _resource, _dataset), do: "dashboard"
  defp section(:dataset, _dashboard, _resource, _dataset), do: "dataset"
  defp section(:index, nil, _resource, dataset) when not is_nil(dataset), do: "dataset"
  defp section(:index, nil, _resource, _dataset), do: "resource"
  defp section(:index, _dashboard, _resource, _dataset), do: "dashboard"

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

  defp page_title(%{section: "dataset", dataset: dataset})
       when not is_nil(dataset) do
    dataset.title || short_module(dataset.module)
  end

  defp page_title(_assigns), do: "Incant"

  defp selected_id(%Incant.Resource.Metadata{id: id}), do: id

  defp selected_id(%Incant.Dashboard.Metadata{} = dashboard),
    do: Incant.Surface.id(dashboard.module, dashboard.opts)

  defp selected_id(%Incant.Dataset.Metadata{} = dataset),
    do: Incant.Surface.id(dataset.module, dataset.opts)

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
