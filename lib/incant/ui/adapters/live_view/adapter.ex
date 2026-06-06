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

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Document
  alias Incant.UI.Regions.WidgetGrid
  alias Incant.UI.Surfaces.{Dashboard, Empty, ResourceIndex}

  @impl Incant.UI.Adapter
  def render(%Document{} = document, env) do
    assigns = %{document: document, env: env, nav: document.nav, surface: document.surface}

    ~H"""
    <div class={Theme.slot(:shell, :root)}>
      <aside class={Theme.slot(:shell, :sidebar)}>
        <div class={Theme.slot(:shell, :brand)}>
          <div class={Theme.slot(:shell, :brand_mark)}>Incant</div>
          <div class={Theme.slot(:shell, :brand_title)}>{short_module(@env.admin)}</div>
        </div>
        <.nav nav={@nav} />
      </aside>

      <main class={Theme.slot(:shell, :main)}>
        <div class={Theme.slot(:shell, :topbar)}>
          <div class={Theme.slot(:shell, :topbar_inner)}>
            <div></div>
            <div class={Theme.slot(:shell, :chrome_count)}>
              {nav_count(@nav, :resource)} resources · {nav_count(@nav, :dashboard)} dashboards
            </div>
          </div>
        </div>

        <div class={Theme.slot(:shell, :body)}>
          <.render_surface surface={@surface} env={@env} />
        </div>
      </main>
    </div>
    """
  end

  def render(node, _env) do
    assigns = %{node: node}

    ~H"""
    <pre class={Theme.slot(:debug, :pre)}><%= inspect(@node, pretty: true) %></pre>
    """
  end

  attr(:nav, :map, required: true)

  def nav(assigns) do
    ~H"""
    <nav class={Theme.slot(:nav, :root)}>
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
      <div class={Theme.slot(:nav, :group_label)}>{@title}</div>
      <div class={Theme.slot(:nav, :group_items)}>
        <.link
          :for={item <- @items}
          patch={item.path}
          class={Theme.slot(:nav_item, :base, active: item.id == @active_id)}
        >
          {item.label}
        </.link>
      </div>
    </div>
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
          <.page_header title={@surface.detail.title} eyebrow="Detail" />
          <.inspector inspector={@surface.detail} env={@env} />
        <% true -> %>
          <.page_header title={@surface.title} eyebrow="Resource" />
          <div class={Theme.slot(:surface, :index)}>
            <div class={Theme.slot(:surface, :primary)}>
              <.table table={@surface.table} env={@env} />
            </div>
            <aside :if={@surface.filter_bar} class={Theme.slot(:surface, :aside)}>
              <.filter_bar filter_bar={@surface.filter_bar} env={@env} />
            </aside>
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
      <.filter_bar :if={@surface.variables != []} filter_bar={List.first(@surface.regions)} env={@env} />
      <.widget_grid grid={Enum.find(@surface.regions, &match?(%WidgetGrid{}, &1))} />
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

  defp nav_count(nav, kind), do: nav.items |> Enum.count(&(&1.kind == kind))
end
