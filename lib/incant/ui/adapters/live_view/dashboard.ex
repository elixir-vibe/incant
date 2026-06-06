defmodule Incant.UI.Adapters.LiveView.Dashboard do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Regions.WidgetGrid

  attr(:grid, WidgetGrid, required: true)

  def widget_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-3 xl:grid-cols-12">
      <.widget :for={widget <- @grid.widgets} widget={widget} />
    </div>
    """
  end

  attr(:widget, :map, required: true)

  def widget(%{widget: %{type: :stat}} = assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3" style={widget_style(@widget)}>
      <p class="text-xs font-medium text-[var(--incant-text-muted)]">{@widget.title}</p>
      <div class="mt-2 text-2xl font-semibold tracking-tight text-[var(--incant-text-highlighted)]">
        <%= if @widget.error do %>
          <span class="text-base text-[var(--incant-error)]">{@widget.error}</span>
        <% else %>
          {@widget.display || "—"}
        <% end %>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :timeseries}} = assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Timeseries</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{@widget.title}</h3>
        </div>
        <span class="inline-flex h-5 items-center rounded-md border border-[var(--incant-border)] px-1.5 text-[11px] leading-none text-[var(--incant-text-muted)]">span {@widget.span || "auto"}</span>
      </div>
      <div :if={is_list(@widget.value) && @widget.value != []} class="mt-3 flex h-36 items-end gap-1.5 rounded-md bg-[var(--incant-bg-muted)] p-3">
        <div :for={point <- @widget.value} class="min-w-2 flex-1 rounded-sm bg-[var(--incant-primary)]" style={"height: #{bar_height(point, @widget.value)}%;"}></div>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :table}} = assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] p-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Table</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{@widget.title}</h3>
        </div>
        <span class="inline-flex h-5 items-center rounded-md border border-[var(--incant-border)] px-1.5 text-[11px] leading-none text-[var(--incant-text-muted)]">span {@widget.span || "auto"}</span>
      </div>
      <table :if={is_list(@widget.value) && @widget.value != []} class="min-w-full text-sm">
        <thead class="bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]">
          <tr><th :for={column <- table_columns(@widget.value)} class="h-8 px-3 font-medium">{column}</th></tr>
        </thead>
        <tbody class="divide-y divide-[var(--incant-border-muted)]">
          <tr :for={row <- @widget.value} class="h-9"><td :for={column <- table_columns(@widget.value)} class="px-3 py-1.5 text-[var(--incant-text-toned)]">{Map.get(row, column)}</td></tr>
        </tbody>
      </table>
    </div>
    """
  end

  def widget(assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3" style={widget_style(@widget)}>
      <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{@widget.type}</p>
      <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{@widget.title}</h3>
    </div>
    """
  end
end
