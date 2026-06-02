defmodule Incant.Live.AdminLive do
  @moduledoc """
  Generic LiveView renderer for an Incant admin surface.
  """

  use Phoenix.LiveView

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

    section = params["section"] || default_section(selected_dashboard, selected_resource)
    table_state = table_state(params)

    {:noreply,
     socket
     |> assign(:params, params)
     |> assign(:section, section)
     |> assign(:selected_resource, selected_resource)
     |> assign(:selected_dashboard, selected_dashboard)
     |> assign(:table_state, table_state)
     |> assign(:resource_rows, resource_rows(selected_resource, table_state))
     |> assign(:widget_values, widget_values(selected_dashboard))}
  end

  @impl Phoenix.LiveView
  def handle_event("table_state", %{"table" => table_params}, socket) do
    resource = socket.assigns.selected_resource

    params =
      socket.assigns.params
      |> Map.take(["section", "resource", "dashboard"])
      |> Map.merge(flatten_table_params(table_params))
      |> reject_empty_values()

    {:noreply,
     push_patch(socket, to: path(socket.assigns.base_path, params_for_resource(params, resource)))}
  end

  def handle_event("sort", %{"column" => column}, socket) do
    params =
      socket.assigns.params
      |> Map.put("sort", next_sort(socket.assigns.params["sort"], column))
      |> reject_empty_values()

    {:noreply, push_patch(socket, to: path(socket.assigns.base_path, params))}
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-zinc-950 text-zinc-100">
      <aside class="fixed inset-y-0 left-0 hidden w-72 border-r border-white/10 bg-zinc-950/95 p-5 lg:block">
        <div>
          <div class="text-xs font-semibold uppercase tracking-[0.35em] text-violet-300">Incant</div>
          <div class="mt-2 text-xl font-semibold">{short_module(@admin.module)}</div>
        </div>

        <nav class="mt-8 space-y-8">
          <div>
            <div class="text-xs font-medium uppercase tracking-widest text-zinc-500">Dashboards</div>
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
            <div class="text-xs font-medium uppercase tracking-widest text-zinc-500">Resources</div>
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
        <div class="border-b border-white/10 bg-zinc-950/70 px-5 py-4 backdrop-blur lg:px-8">
          <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <p class="text-sm text-zinc-400">Admin surface</p>
              <h1 class="text-2xl font-semibold tracking-tight">{page_title(assigns)}</h1>
            </div>
            <div class="flex flex-wrap gap-2 text-xs text-zinc-400">
              <span class="rounded-full border border-white/10 px-3 py-1">{length(@resources)} resources</span>
              <span class="rounded-full border border-white/10 px-3 py-1">{length(@dashboards)} dashboards</span>
              <span :if={@theme} class="rounded-full border border-white/10 px-3 py-1">{@theme.css_vars_prefix}</span>
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
        @active && "bg-violet-500/20 text-violet-100 ring-1 ring-violet-400/30",
        !@active && "text-zinc-400 hover:bg-white/5 hover:text-zinc-100"
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
      <div class="flex flex-col gap-4 rounded-2xl border border-white/10 bg-white/[0.03] p-5">
        <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <p class="text-sm text-zinc-400">Dashboard</p>
            <h2 class="text-3xl font-semibold tracking-tight">{@dashboard.title}</h2>
          </div>
          <div class="font-mono text-xs text-zinc-500">{inspect(@dashboard.grid)}</div>
        </div>

        <div class="flex flex-wrap gap-2">
          <span :for={variable <- @dashboard.variables} class="rounded-full bg-zinc-900 px-3 py-1 text-xs text-zinc-300 ring-1 ring-white/10">
            {variable.name}: {variable.type}
          </span>
        </div>
      </div>

      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <article :for={widget <- @dashboard.widgets} class="rounded-2xl border border-white/10 bg-white/[0.03] p-5 shadow-2xl shadow-black/20">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-sm capitalize text-zinc-400">{widget.type}</p>
              <h3 class="mt-1 font-mono text-lg font-semibold">{widget.id}</h3>
            </div>
            <span class="rounded-full bg-violet-500/15 px-2.5 py-1 text-xs text-violet-200">span {widget.opts[:span] || "auto"}</span>
          </div>
          <div :if={Map.has_key?(@widget_values, widget.id)} class="mt-5 text-3xl font-semibold tracking-tight">
            {format_widget_value(@widget_values[widget.id], widget)}
          </div>
          <pre :if={!Map.has_key?(@widget_values, widget.id)} class="mt-5 overflow-auto rounded-xl bg-black/30 p-3 text-xs text-zinc-400"><%= inspect(widget.opts, pretty: true) %></pre>
        </article>
      </div>
    </section>
    """
  end

  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:rows, :list, default: [])
  attr(:table_state, :map, default: %{})

  def resource_view(assigns) do
    ~H"""
    <section class="space-y-6">
      <div class="rounded-2xl border border-white/10 bg-white/[0.03] p-5">
        <p class="text-sm text-zinc-400">Resource</p>
        <h2 class="mt-1 text-3xl font-semibold tracking-tight">{short_module(@resource.module)}</h2>
        <p class="mt-2 font-mono text-sm text-zinc-500">schema {inspect(@resource.schema)} · repo {inspect(@resource.repo)}</p>

        <.form :let={_form} for={%{}} as={:table} phx-change="table_state" class="mt-5 grid gap-3 md:grid-cols-3">
          <input
            :if={@resource.table.search}
            type="search"
            name="table[search]"
            value={@table_state.search}
            placeholder="Search"
            class="rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-sm text-zinc-100 outline-none placeholder:text-zinc-600 focus:border-violet-400"
          />
          <input
            :for={filter <- @resource.table.filters}
            type="text"
            name={"table[filters][#{filter.name}]"}
            value={Map.get(@table_state.filters, to_string(filter.name), "")}
            placeholder={"#{filter.name} (#{filter.type})"}
            class="rounded-xl border border-white/10 bg-black/30 px-3 py-2 text-sm text-zinc-100 outline-none placeholder:text-zinc-600 focus:border-violet-400"
          />
        </.form>
      </div>

      <div class="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
          <thead class="bg-white/[0.04] text-left text-xs uppercase tracking-wider text-zinc-400">
            <tr>
              <th :for={column <- @resource.table.columns} class="px-4 py-3 font-medium">
                <button type="button" phx-click="sort" phx-value-column={column.name} class="inline-flex items-center gap-1 hover:text-zinc-100">
                  {column.name}
                  <span :if={sort_column(@table_state.sort) == to_string(column.name)}>{sort_direction(@table_state.sort)}</span>
                </button>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr :if={@rows == []}>
              <td colspan={length(@resource.table.columns)} class="px-4 py-10 text-center text-zinc-500">
                No rows. Add a resource data callback or loosen the current filters.
              </td>
            </tr>
            <tr :for={row <- @rows} class="hover:bg-white/[0.02]">
              <td :for={column <- @resource.table.columns} class={cell_class(column)}>
                {render_cell(row, column)}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
    """
  end

  defp resource_rows(nil, _table_state), do: []

  defp resource_rows(resource, table_state) do
    data = resource.data

    data
    |> callback(%{table: table_state}, [])
    |> Incant.Tabular.to_rows(only: Enum.map(resource.table.columns, & &1.name))
    |> search_rows(resource.table.search, table_state.search)
    |> filter_rows(table_state.filters)
    |> sort_rows(table_state.sort)
  rescue
    _error in [ArgumentError, FunctionClauseError, Protocol.UndefinedError] -> []
  end

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

  defp filter_rows(rows, filters) when map_size(filters) == 0, do: rows

  defp filter_rows(rows, filters) do
    Enum.filter(rows, fn row ->
      Enum.all?(filters, fn {field, value} -> filter_match?(row, field, value) end)
    end)
  end

  defp filter_match?(_row, _field, value) when value in [nil, ""], do: true

  defp filter_match?(row, field, value) do
    row
    |> Map.get(String.to_existing_atom(field), "")
    |> to_string()
    |> String.contains?(value)
  rescue
    ArgumentError -> true
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

  defp params_for_resource(params, nil), do: params

  defp params_for_resource(params, resource) do
    params
    |> Map.put_new("section", "resource")
    |> Map.put_new("resource", module_id(resource.module))
  end

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
      "px-4 py-3 text-zinc-300",
      align == :right && "text-right tabular-nums"
    ]
  end

  defp render_cell(row, column) do
    value = Map.get(row, column.name)

    cond do
      render = column.opts[:render] -> callback(render, value, row)
      column.opts[:as] == :badge -> badge(value)
      true -> format_value(value, column.opts[:format])
    end
  end

  defp badge(value) do
    escaped = value |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s(<span class="rounded-full bg-violet-500/15 px-2 py-1 text-xs text-violet-100">#{escaped}</span>)
    )
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

  defp default_section(nil, nil), do: "dashboard"
  defp default_section(nil, _resource), do: "resource"
  defp default_section(_dashboard, _resource), do: "dashboard"

  defp dashboard_path(base_path, dashboard) do
    path(base_path, section: "dashboard", dashboard: module_id(dashboard.module))
  end

  defp resource_path(base_path, resource) do
    path(base_path, section: "resource", resource: module_id(resource.module))
  end

  defp path(base_path, params) do
    base_path <> "?" <> URI.encode_query(params)
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

  defp module_id(module), do: module |> inspect() |> String.replace_prefix("Elixir.", "")

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
