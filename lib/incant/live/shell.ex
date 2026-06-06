defmodule Incant.Live.Shell do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Routes

  attr(:context, Incant.Live.Context, required: true)
  attr(:page_title, :string, required: true)
  slot(:inner_block, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:admin, context.admin)
      |> assign(:resources, context.resources)
      |> assign(:dashboards, context.dashboards)
      |> assign(:theme, context.theme)
      |> assign(:section, context.section)
      |> assign(:selected_resource, context.resource)
      |> assign(:selected_dashboard, context.dashboard)
      |> assign(:base_path, context.base_path)

    ~H"""
    <div class="min-h-screen bg-[var(--incant-bg)] text-[var(--incant-text)] antialiased">
      <aside class="fixed inset-y-0 left-0 hidden w-56 border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] lg:block">
        <div class="border-b border-[var(--incant-border-muted)] px-3 py-2.5">
          <div class="text-[11px] font-semibold uppercase tracking-[0.22em] text-[var(--incant-primary)]">Incant</div>
          <div class="mt-1 text-sm font-medium text-[var(--incant-text-highlighted)]">{short_module(@admin.module)}</div>
        </div>

        <nav class="space-y-4 px-2 py-3">
          <.nav_section title="Dashboards">
            <.nav_item
              :for={dashboard <- @dashboards}
              active={@section == "dashboard" and @selected_dashboard == dashboard}
              patch={dashboard_path(@base_path, dashboard)}
            >
              {dashboard.title || short_module(dashboard.module)}
            </.nav_item>
          </.nav_section>

          <.nav_section title="Resources">
            <.nav_item
              :for={resource <- @resources}
              active={@section == "resource" and @selected_resource == resource}
              patch={resource_path(@base_path, resource)}
            >
              {short_module(resource.module)}
            </.nav_item>
          </.nav_section>
        </nav>
      </aside>

      <main class="lg:pl-56">
        <div class="sticky top-0 z-10 border-b border-[var(--incant-border)] bg-[color-mix(in_oklab,var(--incant-bg-elevated)_92%,transparent)] px-4 backdrop-blur lg:px-5">
          <div class="flex h-11 items-center justify-between gap-3">
            <h1 class="min-w-0 truncate text-sm font-semibold text-[var(--incant-text-highlighted)]">{@page_title}</h1>
            <div class="hidden shrink-0 text-xs text-[var(--incant-text-muted)] md:block">
              {length(@resources)} resources · {length(@dashboards)} dashboards
            </div>
          </div>
        </div>

        <div class="p-3 lg:p-4">
          {render_slot(@inner_block)}
        </div>
      </main>
    </div>
    """
  end

  attr(:title, :string, required: true)
  slot(:inner_block, required: true)

  def nav_section(assigns) do
    ~H"""
    <div>
      <div class="px-2 text-[10px] font-semibold uppercase tracking-wider text-[var(--incant-text-muted)]">{@title}</div>
      <div class="mt-1 space-y-0.5">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr(:active, :boolean, required: true)
  attr(:patch, :string, required: true)
  slot(:inner_block, required: true)

  def nav_item(assigns) do
    ~H"""
    <.link
      patch={@patch}
      class={[
        "block rounded-md px-2 py-1.5 text-sm transition",
        @active && "bg-[var(--incant-bg-muted)] text-[var(--incant-text-highlighted)] shadow-[inset_2px_0_0_var(--incant-primary)]",
        !@active && "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
