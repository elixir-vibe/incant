defmodule Incant.Live.AdminLive do
  @moduledoc """
  Generic LiveView renderer for an Incant admin surface.
  """

  use Phoenix.LiveView

  import Incant.Live.Components

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
    resource_rows = resource_rows(selected_resource, table_state)

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:section, section)
     |> assign(:selected_resource, selected_resource)
     |> assign(:selected_dashboard, selected_dashboard)
     |> assign(:selected_row, resource_row(selected_resource, params["id"]))
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

  attr(:dashboard, Incant.Dashboard.Metadata, required: true)
  attr(:widget_values, :map, default: %{})

  def dashboard_view(assigns) do
    ~H"""
    <section class="space-y-6">
      <.card class="flex flex-col gap-4 p-5">
        <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <p class="text-sm text-[var(--incant-text-muted)]">Dashboard</p>
            <h2 class="text-3xl font-semibold tracking-tight">{@dashboard.title}</h2>
          </div>
          <div class="font-mono text-xs text-[var(--incant-text-muted)]">{inspect(@dashboard.grid)}</div>
        </div>

        <div class="flex flex-wrap gap-2">
          <.pill :for={variable <- @dashboard.variables} class="bg-[var(--incant-bg-accented)] text-[var(--incant-text-toned)]">
            {variable.name}: {variable.type}
          </.pill>
        </div>
      </.card>

      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <.card :for={widget <- @dashboard.widgets} class="p-5 shadow-2xl shadow-[color-mix(in_oklab,var(--incant-bg-inverted)_8%,transparent)]">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-sm capitalize text-[var(--incant-text-muted)]">{widget.type}</p>
              <h3 class="mt-1 font-mono text-lg font-semibold">{widget.id}</h3>
            </div>
            <.pill class="border-0 bg-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)] px-2.5 text-[var(--incant-primary)]">span {widget.opts[:span] || "auto"}</.pill>
          </div>
          <div :if={Map.has_key?(@widget_values, widget.id)} class="mt-5 text-3xl font-semibold tracking-tight">
            {format_widget_value(@widget_values[widget.id], widget)}
          </div>
          <pre :if={!Map.has_key?(@widget_values, widget.id)} class="mt-5 overflow-auto rounded-xl bg-[var(--incant-bg-muted)] p-3 text-xs text-[var(--incant-text-muted)]"><%= inspect(widget.opts, pretty: true) %></pre>
        </.card>
      </div>
    </section>
    """
  end

  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:rows, :list, default: [])
  attr(:selected_row, :any, default: nil)
  attr(:base_path, :string, required: true)
  attr(:table_state, :map, default: %{})

  def resource_view(assigns) do
    ~H"""
    <section class="space-y-6">
      <.card class="p-5">
        <p class="text-sm text-[var(--incant-text-muted)]">Resource</p>
        <h2 class="mt-1 text-3xl font-semibold tracking-tight">{short_module(@resource.module)}</h2>
        <p class="mt-2 font-mono text-sm text-[var(--incant-text-muted)]">schema {inspect(@resource.schema)} · repo {inspect(@resource.repo)}</p>

        <.form :let={_form} for={%{}} as={:table} phx-change="table_state" class="mt-5 grid gap-3 md:grid-cols-3">
          <.input
            :if={@resource.table.search}
            type="search"
            name="table[search]"
            value={@table_state.search}
            placeholder="Search"
          />
          <.filter_control
            :for={filter <- @resource.table.filters}
            filter={filter}
            value={Map.get(@table_state.filters, to_string(filter.name), "")}
          />
        </.form>
      </.card>

      <.card :if={@selected_row} class="p-5">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-sm text-[var(--incant-text-muted)]">Detail</p>
            <h3 class="mt-1 text-xl font-semibold tracking-tight">{row_title(@selected_row, @resource)}</h3>
          </div>
          <.back_link patch={resource_path(@base_path, @resource)}>
            Back to list
          </.back_link>
        </div>
        <dl class="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          <div :for={{key, value} <- row_fields(@selected_row)} class="rounded-xl bg-[var(--incant-bg-muted)] p-3">
            <dt class="text-xs uppercase tracking-wide text-[var(--incant-text-muted)]">{key}</dt>
            <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">{value}</dd>
          </div>
        </dl>
      </.card>

      <.card class="overflow-hidden">
        <table class="min-w-full divide-y divide-[var(--incant-border)] text-sm">
          <thead class="bg-[var(--incant-bg-accented)] text-left text-xs uppercase tracking-wider text-[var(--incant-text-muted)]">
            <tr>
              <th :for={column <- @resource.table.columns} class="px-4 py-3 font-medium">
                <button type="button" phx-click="sort" phx-value-column={column.name} class="inline-flex items-center gap-1 hover:text-[var(--incant-text-highlighted)]">
                  {column.name}
                  <span :if={sort_column(@table_state.sort) == to_string(column.name)}>{sort_direction(@table_state.sort)}</span>
                </button>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[var(--incant-border)]">
            <tr :if={@rows == []}>
              <td colspan={length(@resource.table.columns)} class="px-4 py-10 text-center text-[var(--incant-text-muted)]">
                No rows. Add a resource data callback or loosen the current filters.
              </td>
            </tr>
            <tr :for={row <- @rows} class="hover:bg-[var(--incant-bg-accented)]">
              <td :for={column <- @resource.table.columns} class={cell_class(column)}>
                <.resource_cell row={row} column={column} resource={@resource} base_path={@base_path} />
              </td>
            </tr>
          </tbody>
        </table>
      </.card>
    </section>
    """
  end

  attr(:filter, Incant.Table.Filter, required: true)
  attr(:value, :any, default: nil)

  def filter_control(assigns) do
    ~H"""
    {Incant.Filter.control(@filter, @value, assigns)}
    """
  end

  defp resource_rows(nil, _table_state), do: []

  defp resource_rows(resource, table_state) do
    resource
    |> raw_resource_rows()
    |> Incant.Tabular.to_rows(only: table_row_fields(resource))
    |> search_rows(resource.table.search, table_state.search)
    |> filter_rows(resource.table.filters, table_state.filters)
    |> sort_rows(table_state.sort)
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> []
  end

  defp resource_row(_resource, nil), do: nil

  defp resource_row(resource, id) do
    resource
    |> raw_resource_rows()
    |> Enum.find(&(row_id(&1) == id))
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> nil
  end

  defp table_row_fields(resource), do: [:id | Enum.map(resource.table.columns, & &1.name)]

  defp raw_resource_rows(nil), do: []

  defp raw_resource_rows(resource) do
    callback(resource.data, %{table: %{}}, [])
  end

  defp row_id(row), do: row |> row_field(:id) |> id_string()

  defp id_string(nil), do: nil
  defp id_string(""), do: nil
  defp id_string(value), do: to_string(value)

  defp row_title(row, resource) do
    link_column =
      Enum.find(resource.table.columns, & &1.opts[:link]) || List.first(resource.table.columns)

    case link_column do
      nil -> "Record #{row_id(row)}"
      column -> row |> row_field(column.name) |> to_string()
    end
  end

  defp row_fields(%_struct{} = row) do
    row
    |> Map.from_struct()
    |> Enum.map(fn {key, value} -> {key, format_detail_value(value)} end)
  end

  defp row_fields(row) when is_map(row) do
    Enum.map(row, fn {key, value} -> {key, format_detail_value(value)} end)
  end

  defp row_fields(_row), do: []

  defp row_field(row, field) do
    Map.get(row, field, Map.get(row, to_string(field)))
  end

  defp format_detail_value(value) when is_binary(value), do: value
  defp format_detail_value(value), do: inspect(value)

  defp widget_values(nil), do: %{}

  defp widget_values(dashboard) do
    dashboard.widgets
    |> Enum.filter(&(&1.opts[:query] != nil))
    |> Map.new(fn widget -> {widget.id, callback(widget.opts[:query], %{}, nil)} end)
  end

  defp callback(nil, _params, default), do: default

  defp callback(function, params, _context) when is_function(function, 1), do: function.(params)

  defp callback(function, params, context) when is_function(function, 2),
    do: function.(params, context)

  defp callback({module, function}, params, context),
    do: apply(module, function, [params, context])

  defp callback({module, function, args}, params, context),
    do: apply(module, function, [params, context | args])

  defp search_rows(rows, nil, _search), do: rows
  defp search_rows(rows, _searchable, nil), do: rows
  defp search_rows(rows, _searchable, ""), do: rows

  defp search_rows(rows, searchable, search) do
    fields = List.wrap(searchable)
    needle = String.downcase(search)

    Enum.filter(rows, fn row ->
      Enum.any?(fields, fn field ->
        row
        |> Map.get(field)
        |> to_string()
        |> String.downcase()
        |> String.contains?(needle)
      end)
    end)
  end

  defp filter_rows(rows, _definitions, filters) when map_size(filters) == 0, do: rows

  defp filter_rows(rows, definitions, filters) do
    filters_by_name = Map.new(definitions, &{to_string(&1.name), &1})

    Enum.filter(rows, fn row ->
      Enum.all?(filters, fn {field, value} ->
        case Map.fetch(filters_by_name, field) do
          {:ok, filter} -> Incant.Filter.match?(filter, row, value)
          :error -> true
        end
      end)
    end)
  end

  defp sort_rows(rows, nil), do: rows
  defp sort_rows(rows, ""), do: rows

  defp sort_rows(rows, sort) do
    {direction, field} = sort_parts(sort)

    rows
    |> Enum.sort_by(&Map.get(&1, String.to_existing_atom(field)), sort_direction_fun(direction))
  rescue
    ArgumentError -> rows
  end

  defp sort_parts("-" <> field), do: {:desc, field}
  defp sort_parts(field), do: {:asc, field}

  defp sort_direction_fun(:desc), do: :desc
  defp sort_direction_fun(:asc), do: :asc

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

  defp sort_column("-" <> column), do: column
  defp sort_column(column), do: column

  defp sort_direction("-" <> _column), do: "↓"
  defp sort_direction(_column), do: "↑"

  defp cell_class(column) do
    align = column.opts[:align]

    [
      "px-4 py-3 text-[var(--incant-text-toned)]",
      align == :right && "text-right tabular-nums"
    ]
  end

  attr(:row, :any, required: true)
  attr(:column, Incant.Table.Column, required: true)
  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:base_path, :string, required: true)

  def resource_cell(assigns) do
    assigns =
      assigns
      |> assign(:value, row_field(assigns.row, assigns.column.name))
      |> assign(:row_id, row_id(assigns.row))

    ~H"""
    <.primary_link :if={@column.opts[:link] && @row_id} patch={resource_detail_path(@base_path, @resource, @row_id)}>
      <.cell_value row={@row} column={@column} value={@value} />
    </.primary_link>
    <.cell_value :if={!@column.opts[:link] || !@row_id} row={@row} column={@column} value={@value} />
    """
  end

  attr(:row, :any, required: true)
  attr(:column, Incant.Table.Column, required: true)
  attr(:value, :any, required: true)

  def cell_value(assigns) do
    assigns =
      assign(assigns, :rendered, render_cell_value(assigns.row, assigns.column, assigns.value))

    ~H"""
    <.badge :if={@column.opts[:as] == :badge} tone={:primary}>{@value}</.badge>
    <span :if={@column.opts[:as] != :badge}>{@rendered}</span>
    """
  end

  defp render_cell_value(row, column, value) do
    case column.opts[:render] do
      nil -> format_value(value, column.opts[:format])
      render -> callback(render, value, row)
    end
  end

  defp format_widget_value(value, widget), do: format_value(value, widget.opts[:format])

  defp format_value(value, :money), do: format_currency(value)
  defp format_value(value, :currency), do: format_currency(value)
  defp format_value(value, :percent) when is_number(value), do: "#{Float.round(value * 100, 2)}%"
  defp format_value(value, :relative), do: to_string(value)
  defp format_value(value, _format), do: to_string(value)

  defp format_currency(value) when is_integer(value), do: "$#{value}"

  defp format_currency(value) when is_float(value),
    do: "$#{:erlang.float_to_binary(value, decimals: 2)}"

  defp format_currency(value), do: to_string(value)

  defp theme_metadata(admin) do
    case admin.opts[:theme] do
      nil -> nil
      module -> Incant.metadata(module)
    end
  end

  defp select_by_module(collection, nil), do: List.first(collection)

  defp select_by_module(collection, module_id) do
    Enum.find(collection, &(module_id(&1.module) == module_id))
  end

  defp section(%{"resource" => _resource_param}, _dashboard, _selected_resource), do: "resource"

  defp section(%{"dashboard" => _dashboard_param}, _dashboard_metadata, _resource),
    do: "dashboard"

  defp section(_params, nil, _resource), do: "resource"
  defp section(_params, _dashboard, _resource), do: "dashboard"

  defp current_path(
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

  defp current_path(
         %{section: "dashboard", selected_dashboard: dashboard, base_path: base_path},
         query_params
       ) do
    dashboard_path(base_path, dashboard, query_params)
  end

  defp dashboard_path(base_path, dashboard, query_params \\ %{}) do
    path([base_path, "dashboards", module_id(dashboard.module)], query_params)
  end

  defp resource_path(base_path, resource, query_params \\ %{}) do
    path([base_path, "resources", module_id(resource.module)], query_params)
  end

  defp resource_detail_path(base_path, resource, id, query_params \\ %{}) do
    path([base_path, "resources", module_id(resource.module), id], query_params)
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

  defp page_title(%{section: "resource", selected_resource: resource})
       when not is_nil(resource) do
    short_module(resource.module)
  end

  defp page_title(%{section: "dashboard", selected_dashboard: dashboard})
       when not is_nil(dashboard) do
    dashboard.title || short_module(dashboard.module)
  end

  defp page_title(_assigns), do: "Incant"

  defp module_id(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
