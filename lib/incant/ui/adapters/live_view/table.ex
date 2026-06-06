defmodule Incant.UI.Adapters.LiveView.Table do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Routes
  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Regions.Table

  attr(:table, Table, required: true)
  attr(:env, :map, required: true)

  def table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <table class="min-w-full text-sm">
        <thead class="border-b border-[var(--incant-border)] bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]">
          <tr>
            <th :for={column <- @table.columns} class="h-8 px-3 font-medium">
              <button type="button" phx-click="incant:event" phx-value-op="sort" phx-value-target={column.id} class="inline-flex items-center gap-1 rounded px-1 py-0.5 hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]">
                {column.id}
                <span :if={sort_column(@table.sort) == column.id}>{sort_direction(@table.sort)}</span>
              </button>
            </th>
            <th :if={@table.row_actions != []} class="h-8 px-3 text-right font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-[var(--incant-border-muted)]">
          <tr :if={@table.rows == []}>
            <td colspan={length(@table.columns)} class="px-3 py-8 text-center text-sm text-[var(--incant-text-muted)]">{@table.empty_state}</td>
          </tr>
          <tr :for={row <- @table.rows} class="h-9 hover:bg-[var(--incant-bg-muted)]">
            <td :for={cell <- row.cells} class={cell_class(cell)}>
              <.table_cell cell={cell} row={row} env={@env} />
            </td>
            <td :if={@table.row_actions != []} class="px-3 py-1.5 text-right">
              <.row_actions row={row} actions={@table.row_actions} env={@env} />
            </td>
          </tr>
        </tbody>
      </table>
      <.pagination pagination={@table.pagination} />
    </div>
    """
  end

  def table_cell(assigns) do
    assigns = assign(assigns, :column, assigns.cell.source)

    ~H"""
    <.link :if={detail_link?(@env.context, @column, @row.source, @row.id)} patch={resource_detail_path(@env.base_path, @env.context.resource, @row.id)} class="font-medium text-[var(--incant-text-highlighted)] hover:underline">
      <.cell_value cell={@cell} />
    </.link>
    <.cell_value :if={!detail_link?(@env.context, @column, @row.source, @row.id)} cell={@cell} />
    """
  end

  attr(:cell, :map, required: true)

  def cell_value(assigns) do
    ~H"""
    <span :if={@cell.format == :badge} class="inline-flex h-5 items-center rounded-md bg-[var(--incant-bg-muted)] px-1.5 text-[11px] font-medium leading-none text-[var(--incant-text-toned)]">{@cell.value}</span>
    <span :if={@cell.format != :badge}>{@cell.display}</span>
    """
  end

  attr(:row, :map, required: true)
  attr(:actions, :list, required: true)
  attr(:env, :map, required: true)

  def row_actions(assigns) do
    ~H"""
    <div class="inline-flex items-center gap-1">
      <%= for action <- @actions, action_allowed?(@env.context, action, @row.source) do %>
        <.link :if={action.name == :edit && @row.id && form_enabled?(@env.context.resource)} patch={resource_edit_path(@env.base_path, @env.context.resource, @row.id)} class={action_class(action)}>
          {action_label(action)}
        </.link>
        <button :if={action.name != :edit || !form_enabled?(@env.context.resource)} type="button" class={action_class(action)} phx-click="incant:event" phx-value-op="row_action" phx-value-target={action.name} phx-value-value={@row.id} data-confirm={action.opts[:confirm] && "Are you sure?"}>
          {action_label(action)}
        </button>
      <% end %>
    </div>
    """
  end

  def pagination(%{pagination: %{total: total}} = assigns) when total > 0 do
    ~H"""
    <div class="flex h-10 items-center justify-between gap-3 border-t border-[var(--incant-border)] px-3 text-xs text-[var(--incant-text-muted)]">
      <div>Page {@pagination.page} of {@pagination.total_pages} · {@pagination.total} rows</div>
      <div class="flex items-center gap-1">
        <button type="button" phx-click="incant:event" phx-value-op="paginate" phx-value-value={@pagination.page - 1} disabled={@pagination.page <= 1} class="rounded-md border border-[var(--incant-border)] px-2 py-1 disabled:opacity-40 hover:bg-[var(--incant-bg-accented)]">Previous</button>
        <button type="button" phx-click="incant:event" phx-value-op="paginate" phx-value-value={@pagination.page + 1} disabled={@pagination.page >= @pagination.total_pages} class="rounded-md border border-[var(--incant-border)] px-2 py-1 disabled:opacity-40 hover:bg-[var(--incant-bg-accented)]">Next</button>
      </div>
    </div>
    """
  end

  def pagination(assigns) do
    ~H"""
    """
  end
end
