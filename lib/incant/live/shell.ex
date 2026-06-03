defmodule Incant.Live.Shell do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
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
    <div class="min-h-screen bg-[var(--incant-bg)] text-[var(--incant-text)]">
      <aside class="fixed inset-y-0 left-0 hidden w-72 border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-5 lg:block">
        <div>
          <div class="text-xs font-semibold uppercase tracking-[0.35em] text-[var(--incant-primary)]">Incant</div>
          <div class="mt-2 text-xl font-semibold">{short_module(@admin.module)}</div>
        </div>

        <nav class="mt-8 space-y-8">
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

      <main class="lg:pl-72">
        <div class="border-b border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-5 py-4 backdrop-blur lg:px-8">
          <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div>
              <p class="text-sm text-[var(--incant-text-muted)]">Admin surface</p>
              <h1 class="text-2xl font-semibold tracking-tight">{@page_title}</h1>
            </div>
            <div class="flex flex-wrap gap-2 text-xs text-[var(--incant-text-muted)]">
              <.pill>{length(@resources)} resources</.pill>
              <.pill>{length(@dashboards)} dashboards</.pill>
              <.pill :if={@theme}>{@theme.css_vars_prefix}</.pill>
            </div>
          </div>
        </div>

        <div class="p-5 lg:p-8">
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
      <div class="text-xs font-medium uppercase tracking-widest text-[var(--incant-text-muted)]">{@title}</div>
      <div class="mt-3 space-y-1">
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
        "block rounded-lg px-3 py-2 text-sm transition",
        @active && "bg-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)] text-[var(--incant-text-highlighted)] ring-1 ring-[color-mix(in_oklab,var(--incant-primary)_35%,transparent)]",
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
