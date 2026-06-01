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

    {:noreply,
     socket
     |> assign(:section, section)
     |> assign(:selected_resource, selected_resource)
     |> assign(:selected_dashboard, selected_dashboard)}
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
          <.dashboard_view :if={@section == "dashboard" and @selected_dashboard} dashboard={@selected_dashboard} />
          <.resource_view :if={@section == "resource" and @selected_resource} resource={@selected_resource} />
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
          <pre class="mt-5 overflow-auto rounded-xl bg-black/30 p-3 text-xs text-zinc-400"><%= inspect(widget.opts, pretty: true) %></pre>
        </article>
      </div>
    </section>
    """
  end

  attr(:resource, Incant.Resource.Metadata, required: true)

  def resource_view(assigns) do
    ~H"""
    <section class="space-y-6">
      <div class="rounded-2xl border border-white/10 bg-white/[0.03] p-5">
        <p class="text-sm text-zinc-400">Resource</p>
        <h2 class="mt-1 text-3xl font-semibold tracking-tight">{short_module(@resource.module)}</h2>
        <p class="mt-2 font-mono text-sm text-zinc-500">schema {inspect(@resource.schema)} · repo {inspect(@resource.repo)}</p>

        <div class="mt-5 flex flex-wrap gap-2">
          <span :for={filter <- @resource.table.filters} class="rounded-full bg-zinc-900 px-3 py-1 text-xs text-zinc-300 ring-1 ring-white/10">
            filter {filter.name}: {filter.type}
          </span>
          <span :if={@resource.table.search} class="rounded-full bg-zinc-900 px-3 py-1 text-xs text-zinc-300 ring-1 ring-white/10">
            search {inspect(@resource.table.search)}
          </span>
        </div>
      </div>

      <div class="overflow-hidden rounded-2xl border border-white/10 bg-white/[0.03]">
        <table class="min-w-full divide-y divide-white/10 text-sm">
          <thead class="bg-white/[0.04] text-left text-xs uppercase tracking-wider text-zinc-400">
            <tr>
              <th :for={column <- @resource.table.columns} class="px-4 py-3 font-medium">
                {column.name}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-white/10">
            <tr>
              <td colspan={length(@resource.table.columns)} class="px-4 py-10 text-center text-zinc-500">
                Data execution comes next. This table is rendered from resource metadata.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
    """
  end

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
