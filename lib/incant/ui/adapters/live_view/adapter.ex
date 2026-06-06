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

  alias Incant.UI.Document
  alias Incant.UI.Regions.WidgetGrid
  alias Incant.UI.Surfaces.{Dashboard, Empty, ResourceIndex}

  @impl Incant.UI.Adapter
  def render(%Document{} = document, env) do
    assigns = %{document: document, env: env, nav: document.nav, surface: document.surface}

    ~H"""
    <div class="min-h-screen bg-[var(--incant-bg)] text-[var(--incant-text)] antialiased">
      <aside class="fixed inset-y-0 left-0 hidden w-56 border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] lg:block">
        <div class="border-b border-[var(--incant-border-muted)] px-3 py-2.5">
          <div class="text-[11px] font-semibold uppercase tracking-[0.22em] text-[var(--incant-primary)]">Incant</div>
          <div class="mt-1 text-sm font-medium text-[var(--incant-text-highlighted)]">{short_module(@env.admin)}</div>
        </div>
        <.nav nav={@nav} />
      </aside>

      <main class="lg:pl-56">
        <div class="sticky top-0 z-10 border-b border-[var(--incant-border)] bg-[color-mix(in_oklab,var(--incant-bg-elevated)_92%,transparent)] px-4 backdrop-blur lg:px-5">
          <div class="flex h-11 items-center justify-between gap-3">
            <h1 class="min-w-0 truncate text-sm font-semibold text-[var(--incant-text-highlighted)]">{@document.title}</h1>
            <div class="hidden shrink-0 text-xs text-[var(--incant-text-muted)] md:block">
              {nav_count(@nav, :resource)} resources · {nav_count(@nav, :dashboard)} dashboards
            </div>
          </div>
        </div>

        <div class="p-3 lg:p-4">
          <.render_surface surface={@surface} env={@env} />
        </div>
      </main>
    </div>
    """
  end

  def render(node, _env) do
    assigns = %{node: node}

    ~H"""
    <pre class="rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-muted)] p-3 text-xs text-[var(--incant-text-muted)]"><%= inspect(@node, pretty: true) %></pre>
    """
  end

  attr(:nav, :map, required: true)

  def nav(assigns) do
    ~H"""
    <nav class="space-y-4 px-2 py-3">
      <.nav_group title="Dashboards" items={Enum.filter(@nav.items, &(&1.group == :dashboards))} active_id={@nav.active_id} />
      <.nav_group title="Resources" items={Enum.filter(@nav.items, &(&1.group == :resources))} active_id={@nav.active_id} />
    </nav>
    """
  end

  attr(:title, :string, required: true)
  attr(:items, :list, required: true)
  attr(:active_id, :string, default: nil)

  def nav_group(assigns) do
    ~H"""
    <div>
      <div class="px-2 text-[10px] font-semibold uppercase tracking-wider text-[var(--incant-text-muted)]">{@title}</div>
      <div class="mt-1 space-y-0.5">
        <.link
          :for={item <- @items}
          patch={item.path}
          class={[
            "block rounded-md px-2 py-1.5 text-sm transition",
            item.id == @active_id && "bg-[var(--incant-bg-muted)] text-[var(--incant-text-highlighted)] shadow-[inset_2px_0_0_var(--incant-primary)]",
            item.id != @active_id && "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
          ]}
        >
          {item.label}
        </.link>
      </div>
    </div>
    """
  end

  attr(:surface, :any, required: true)
  attr(:env, :map, required: true)

  def render_surface(%{surface: %ResourceIndex{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class="space-y-3">
      <.filter_bar :if={@surface.filter_bar} filter_bar={@surface.filter_bar} env={@env} />
      <.resource_form :if={@surface.form} form={@surface.form} env={@env} />
      <.inspector :if={@surface.detail} inspector={@surface.detail} env={@env} />
      <.table table={@surface.table} env={@env} />
    </section>
    """
  end

  def render_surface(%{surface: %Dashboard{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class="space-y-3">
      <.filter_bar :if={@surface.variables != []} filter_bar={List.first(@surface.regions)} env={@env} />
      <.widget_grid grid={Enum.find(@surface.regions, &match?(%WidgetGrid{}, &1))} />
    </section>
    """
  end

  def render_surface(%{surface: %Empty{context: %{authorization: {:error, reason}}}} = assigns) do
    assigns = assign(assigns, :message, authorization_message(reason))

    ~H"""
    <section class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-6 text-center">
      <p class="text-sm text-[var(--incant-text-muted)]">Access denied</p>
      <h2 class="mt-2 text-xl font-semibold tracking-tight">{@message}</h2>
    </section>
    """
  end

  def render_surface(assigns) do
    ~H"""
    """
  end

  defp nav_count(nav, kind), do: nav.items |> Enum.count(&(&1.kind == kind))
end
