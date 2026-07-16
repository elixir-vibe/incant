defmodule Incant.UI.Adapters.LiveView do
  @moduledoc """
  Default Incant UI adapter backed by Phoenix LiveView components.
  """

  @behaviour Incant.UI.Adapter

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Controls
  import Incant.UI.Adapters.LiveView.Dashboard
  import Incant.UI.Adapters.LiveView.Form
  import Incant.UI.Adapters.LiveView.Helpers
  import Incant.UI.Adapters.LiveView.Inspector
  import Incant.UI.Adapters.LiveView.Table
  import Incant.Live.Routes

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Document
  alias Incant.UI.Regions.WidgetGrid

  alias Incant.UI.Surfaces.{
    Dashboard,
    DatasetIndex,
    Empty,
    ResourceIndex,
    SectionIndex,
    ServiceIndex
  }

  alias Phoenix.LiveView.JS

  @impl Incant.UI.Adapter
  def render(%Document{} = document, env) do
    assigns = %{
      document: document,
      env: env,
      nav: document.nav,
      surface: document.surface,
      flashes: flash_entries(env.flash)
    }

    ~H"""
    <div class={Theme.slot(:shell, :root)} data-incant-shell>
      <div class={Theme.slot(:shell, :sidebar_backdrop)} data-incant-nav-backdrop aria-hidden="true"></div>
      <aside id="incant-primary-navigation" class={Theme.slot(:shell, :sidebar)} data-incant-sidebar aria-label="Primary navigation">
        <div class={Theme.slot(:shell, :brand)}>
          <div class={Theme.slot(:shell, :brand_mark)}>Incant</div>
          <div class={Theme.slot(:shell, :brand_title)}>{short_module(@env.admin)}</div>
        </div>
        <.nav nav={@nav} />
      </aside>

      <main class={Theme.slot(:shell, :main)}>
        <div class={Theme.slot(:shell, :topbar)}>
          <div class={Theme.slot(:shell, :topbar_inner)}>
            <button
              type="button"
              class={[Theme.slot(:shell, :icon_button), Theme.slot(:shell, :mobile_nav_toggle)]}
              aria-label="Open navigation"
              aria-controls="incant-primary-navigation"
              aria-expanded="false"
              data-incant-nav-toggle
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" class="h-4 w-4">
                <path stroke-linecap="round" d="M4 7h16M4 12h16M4 17h16" />
              </svg>
            </button>
            <.breadcrumbs items={breadcrumb_items(@env.context, @surface)} />
            <div class={Theme.slot(:shell, :topbar_actions)}>
              <button type="button" class={Theme.slot(:shell, :icon_button)} aria-label="Toggle dark mode" data-incant-theme-toggle>
                <svg data-incant-theme-icon="sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" class="h-4 w-4">
                  <circle cx="12" cy="12" r="4" />
                  <path stroke-linecap="round" d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41" />
                </svg>
                <svg data-incant-theme-icon="moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" class="hidden h-4 w-4">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M20.35 15.5A8.5 8.5 0 0 1 8.5 3.65 8.5 8.5 0 1 0 20.35 15.5Z" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <div class={Theme.slot(:shell, :body)}>
          <.render_surface surface={@surface} env={@env} />
        </div>
      </main>
      <.flash_region flashes={@flashes} />
    </div>
    """
  end

  def render(node, _env) do
    assigns = %{node: node}

    ~H"""
    <pre class={Theme.slot(:debug, :pre)}><%= inspect(@node, pretty: true) %></pre>
    """
  end

  attr(:flashes, :list, required: true)

  def flash_region(assigns) do
    ~H"""
    <div :if={@flashes != []} class={Theme.slot(:toast, :region)} aria-live="polite" role="status">
      <div :for={{level, message} <- @flashes} id={"incant-flash-#{level}"} class={Theme.slot(:toast, :root, level: level)} data-incant-flash>
        <span class={Theme.slot(:toast, :message)}>{message}</span>
        <button
          type="button"
          class={Theme.slot(:toast, :close)}
          aria-label={"Dismiss #{level} notification"}
          phx-click={dismiss_flash(level)}
          data-incant-flash-close
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" class="h-4 w-4">
            <path stroke-linecap="round" d="m6 6 12 12M18 6 6 18" />
          </svg>
        </button>
      </div>
    </div>
    """
  end

  attr(:nav, :map, required: true)

  def nav(assigns) do
    ~H"""
    <nav class={Theme.slot(:nav, :root)}>
      <.nav_group title="Dashboards" items={Enum.filter(@nav.items, &(&1.group == :dashboards))} active_id={@nav.active_id} />
      <.nav_group title="Datasets" items={Enum.filter(@nav.items, &(&1.group == :datasets))} active_id={@nav.active_id} />
      <.nav_group title="Resources" items={Enum.filter(@nav.items, &(&1.group == :resources))} active_id={@nav.active_id} />
    </nav>
    """
  end

  attr(:title, :string, required: true)
  attr(:items, :list, required: true)
  attr(:active_id, :string, default: nil)

  def nav_group(assigns) do
    ~H"""
    <div :if={@items != []}>
      <div class={Theme.slot(:nav, :group_label)}>{@title}</div>
      <div class={Theme.slot(:nav, :group_items)}>
        <.link
          :for={item <- @items}
          href={item.path}
          class={Theme.slot(:nav_item, :base, active: item.id == @active_id)}
          aria-current={if(item.id == @active_id, do: "page")}
        >
          {item.label}
        </.link>
      </div>
    </div>
    """
  end

  attr(:items, :list, required: true)

  def breadcrumbs(assigns) do
    ~H"""
    <nav aria-label="Breadcrumb" class={Theme.slot(:shell, :breadcrumb)}>
      <%= for {item, index} <- Enum.with_index(@items) do %>
        <span :if={index > 0} aria-hidden="true" class={Theme.slot(:shell, :breadcrumb_separator)}>/</span>
        <.link
          :if={item.path}
          href={item.path}
          class={Theme.slot(:shell, :breadcrumb_link)}
        >
          {item.label}
        </.link>
        <span
          :if={!item.path}
          class={if(index == length(@items) - 1, do: Theme.slot(:shell, :breadcrumb_current), else: Theme.slot(:shell, :breadcrumb_muted))}
          aria-current={if(index == length(@items) - 1, do: "page")}
        >
          {item.label}
        </span>
      <% end %>
    </nav>
    """
  end

  attr(:title, :string, required: true)
  attr(:eyebrow, :string, required: true)

  def page_header(assigns) do
    ~H"""
    <header class={Theme.slot(:page_header, :root)}>
      <div>
        <p class={Theme.slot(:page_header, :eyebrow)}>{@eyebrow}</p>
        <h2 class={Theme.slot(:page_header, :title)}>{@title}</h2>
      </div>
    </header>
    """
  end

  attr(:surface, :any, required: true)
  attr(:env, :map, required: true)

  def render_surface(%{surface: %ResourceIndex{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class={Theme.slot(:surface, :stack)}>
      <%= cond do %>
        <% @surface.form -> %>
          <.page_header title={@surface.title} eyebrow={form_eyebrow(@surface.form.mode)} />
          <.resource_form form={@surface.form} env={@env} />
        <% @surface.detail -> %>
          <.inspector inspector={@surface.detail} env={@env} />
        <% true -> %>
          <.page_header title={@surface.title} eyebrow="Resource" />
          <div class={Theme.slot(:surface, :index)}>
            <div class={Theme.slot(:surface, :primary)}>
              <.table table={@surface.table} filter_bar={@surface.filter_bar} env={@env} />
            </div>
          </div>
      <% end %>
    </section>
    """
  end

  def render_surface(%{surface: %Dashboard{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class={Theme.slot(:surface, :stack)}>
      <.page_header title={@surface.title} eyebrow="Dashboard" />
      <.dashboard_variables variables={@surface.variables} env={@env} />
      <.widget_grid grid={Enum.find(@surface.regions, &match?(%WidgetGrid{}, &1))} />
    </section>
    """
  end

  def render_surface(%{surface: %DatasetIndex{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class={Theme.slot(:surface, :stack)}>
      <.page_header title={@surface.title} eyebrow="Dataset" />
      <div :if={@surface.drilldowns != []} class={Theme.slot(:dataset, :drilldowns)}>
        <.link
          :for={drilldown <- @surface.drilldowns}
          patch={drilldown.path}
          class={Theme.slot(:button, :base, variant: if(drilldown.active, do: :primary, else: :outline), size: :xs)}
        >
          {drilldown.label}
        </.link>
      </div>
      <div class={Theme.slot(:surface, :index)}>
        <div class={Theme.slot(:surface, :primary)}>
          <.table table={@surface.table} filter_bar={@surface.filter_bar} env={@env} />
        </div>
      </div>
    </section>
    """
  end

  def render_surface(%{surface: %SectionIndex{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class={Theme.slot(:surface, :stack)}>
      <.page_header title={@surface.title} eyebrow={@surface.eyebrow} />
      <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        <.link
          :for={item <- @surface.items}
          href={item.path}
          class="block rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-4 text-sm font-medium text-[var(--incant-text-highlighted)] transition-colors hover:border-[var(--incant-primary)] hover:bg-[var(--incant-bg-accented)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--incant-primary)]"
        >
          {item.label}
        </.link>
      </div>
      <div :if={@surface.items == []} class={Theme.slot(:panel, :root, kind: :empty)}>
        <p class={Theme.slot(:panel, :empty_title)}>No {String.downcase(@surface.title)} available.</p>
      </div>
    </section>
    """
  end

  def render_surface(%{surface: %ServiceIndex{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class={Theme.slot(:surface, :stack)}>
      <.page_header title={@surface.title} eyebrow="Incant Admin" />

      <div class="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
        <.link
          :for={service <- @surface.services}
          href={service_path(@surface.base_path, service)}
          class="block rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-4 transition-colors hover:border-[var(--incant-primary)] hover:bg-[var(--incant-bg-accented)]"
        >
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
                Service
              </p>
              <h3 class="mt-1 text-lg font-semibold text-[var(--incant-text-highlighted)]">
                {service.service || service.key || service.id}
              </h3>
            </div>
            <span :if={service.version} class="rounded-full border border-[var(--incant-border)] px-2 py-0.5 text-xs text-[var(--incant-text-muted)]">
              v{service.version}
            </span>
          </div>

          <div class="mt-4 grid grid-cols-3 gap-2 text-sm">
            <div>
              <div class="text-lg font-semibold text-[var(--incant-text-highlighted)]">{service.surfaces.resources}</div>
              <div class="text-xs text-[var(--incant-text-muted)]">Resources</div>
            </div>
            <div>
              <div class="text-lg font-semibold text-[var(--incant-text-highlighted)]">{service.surfaces.datasets}</div>
              <div class="text-xs text-[var(--incant-text-muted)]">Datasets</div>
            </div>
            <div>
              <div class="text-lg font-semibold text-[var(--incant-text-highlighted)]">{service.surfaces.dashboards}</div>
              <div class="text-xs text-[var(--incant-text-muted)]">Dashboards</div>
            </div>
          </div>
        </.link>
      </div>

      <div :if={@surface.services == []} class={Theme.slot(:panel, :root, kind: :empty)}>
        <p class={Theme.slot(:panel, :title)}>No services discovered</p>
        <h2 class={Theme.slot(:panel, :empty_title)}>Incant registry is empty.</h2>
      </div>
    </section>
    """
  end

  def render_surface(%{surface: %Empty{context: %{authorization: {:error, reason}}}} = assigns) do
    assigns = assign(assigns, :message, authorization_message(reason))

    ~H"""
    <section class={Theme.slot(:panel, :root, kind: :empty)}>
      <p class={Theme.slot(:panel, :title)}>Access denied</p>
      <h2 class={Theme.slot(:panel, :empty_title)}>{@message}</h2>
    </section>
    """
  end

  def render_surface(assigns) do
    ~H"""
    """
  end

  defp flash_entries(flash) when is_map(flash) do
    Enum.flat_map([:info, :error], fn level ->
      case Map.get(flash, level) || Map.get(flash, to_string(level)) do
        message when is_binary(message) and message != "" -> [{level, message}]
        _other -> []
      end
    end)
  end

  defp flash_entries(_flash), do: []

  defp dismiss_flash(level) do
    JS.push("lv:clear-flash", value: %{key: to_string(level)})
    |> JS.hide(
      to: "#incant-flash-#{level}",
      transition: {"transition-opacity", "opacity-100", "opacity-0"}
    )
  end

  defp breadcrumb_items(context, surface) do
    [
      %{label: "Incant", path: breadcrumb_root_path(context)},
      %{label: service_name(context), path: service_breadcrumb_path(context)},
      %{label: section_name(context), path: section_breadcrumb_path(context)},
      %{label: surface.title, path: nil}
    ]
    |> Enum.reject(&is_nil(&1.label))
    |> Enum.uniq_by(& &1.label)
  end

  defp breadcrumb_root_path(%{session: %{entry: _entry}, base_path: base_path}) do
    case Path.dirname(base_path) do
      "." -> "/"
      path -> path
    end
  end

  defp breadcrumb_root_path(%{base_path: base_path}) when is_binary(base_path), do: base_path
  defp breadcrumb_root_path(_context), do: "/"

  defp service_breadcrumb_path(%{session: %{entry: _entry}, base_path: base_path}), do: base_path
  defp service_breadcrumb_path(_context), do: nil

  defp section_breadcrumb_path(%{section: "dashboard", base_path: base_path}),
    do: dashboard_index_path(base_path)

  defp section_breadcrumb_path(%{section: "dataset", base_path: base_path}),
    do: dataset_index_path(base_path)

  defp section_breadcrumb_path(%{section: "resource", base_path: base_path}),
    do: resource_index_path(base_path)

  defp section_breadcrumb_path(_context), do: nil

  defp service_name(%{session: %{entry: %{contract: %{service: service}}}}),
    do: to_string(service)

  defp service_name(_context), do: nil

  defp section_name(%{section: section}) when section in ["dashboard", "dashboards"],
    do: "Dashboards"

  defp section_name(%{section: section}) when section in ["dataset", "datasets"], do: "Datasets"

  defp section_name(%{section: section}) when section in ["resource", "resources"],
    do: "Resources"

  defp section_name(%{section: "services"}), do: "Services"
  defp section_name(_context), do: nil

  defp service_path(base_path, service) do
    Path.join(base_path || "/", service.id)
  end
end
