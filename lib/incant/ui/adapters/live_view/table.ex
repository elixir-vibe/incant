defmodule Incant.UI.Adapters.LiveView.Table do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Routes
  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Regions.Table

  attr(:table, Table, required: true)
  attr(:env, :map, required: true)

  def table(assigns) do
    ~H"""
    <div class={Theme.slot(:panel, :root, kind: :table)}>
      <.table_toolbar table={@table} env={@env} />
      <div class={Theme.slot(:table, :viewport)}>
        <table class={Theme.slot(:table, :root)}>
        <thead class={Theme.slot(:table, :head)}>
          <tr>
            <th :if={@table.selection && @table.selection.enabled} class={Theme.slot(:table, :checkbox_cell)}></th>
            <th :for={column <- @table.columns} class={table_header_class(column)}>
              <button type="button" phx-click="incant:event" phx-value-op="sort" phx-value-target={column.id} class={table_sort_button_class(column)}>
                {column.label}
                <span :if={sort_column(@table.sort) == column.id}>{sort_direction(@table.sort)}</span>
              </button>
            </th>
            <th :if={@table.row_actions != []} class={Theme.slot(:table, :header_cell, align: :right)}>Actions</th>
          </tr>
        </thead>
        <tbody class={Theme.slot(:table, :body)}>
          <tr :if={@table.rows == []}>
            <td colspan={empty_colspan(@table)} class={Theme.slot(:table, :empty)}>{@table.empty_state}</td>
          </tr>
          <tr :for={row <- @table.rows} class={Theme.slot(:table, :row)}>
            <td :if={@table.selection && @table.selection.enabled} class={Theme.slot(:table, :checkbox_cell)}>
              <button type="button" phx-click="incant:event" phx-value-op="row_select" phx-value-value={row.id} aria-pressed={selected?(@table, row.id)} class={Theme.slot(:table, :checkbox)}>
                <span :if={selected?(@table, row.id)}>✓</span>
              </button>
            </td>
            <td :for={cell <- row.cells} class={cell_class(cell)} title={cell_title(cell)}>
              <.table_cell cell={cell} row={row} env={@env} />
            </td>
            <td :if={@table.row_actions != []} class={Theme.slot(:table, :actions)}>
              <.row_actions row={row} actions={@table.row_actions} env={@env} />
            </td>
          </tr>
        </tbody>
        </table>
      </div>
      <.pagination pagination={@table.pagination} />
    </div>
    """
  end

  attr(:table, Table, required: true)
  attr(:env, :map, required: true)

  def table_toolbar(assigns) do
    ~H"""
    <div :if={@table.bulk_actions != [] || @table.page_actions != []} class={Theme.slot(:table, :toolbar)}>
      <div class={Theme.slot(:table, :toolbar_group)}>
        <span :if={@table.bulk_actions != []} class={Theme.slot(:table, :toolbar_hint)}>
          {selected_count(@table)} selected
        </span>
        <button
          :for={action <- @table.bulk_actions}
          type="button"
          class={Theme.slot(:button, :base, variant: :outline, size: :xs)}
          phx-click="incant:event"
          phx-value-op="bulk_action"
          phx-value-target={action.name}
          disabled={selected_count(@table) == 0}
          data-confirm={confirm_message(action)}
        >
          {action_label(action)}
        </button>
      </div>
      <div class={Theme.slot(:table, :toolbar_group)}>
        <button
          :for={action <- @table.page_actions}
          type="button"
          class={Theme.slot(:button, :base, variant: :outline, size: :xs)}
          phx-click="incant:event"
          phx-value-op="page_action"
          phx-value-target={action.name}
          data-confirm={confirm_message(action)}
        >
          {action_label(action)}
        </button>
      </div>
    </div>
    """
  end

  def table_cell(assigns) do
    assigns = assign(assigns, :column, assigns.cell.source)

    ~H"""
    <.link :if={detail_link?(@env.context, @column, @row.source, @row.id)} patch={resource_detail_path(@env.base_path, @env.context.resource, @row.id)} class={Theme.slot(:table, :link)}>
      <.cell_value cell={@cell} />
    </.link>
    <.cell_value :if={!detail_link?(@env.context, @column, @row.source, @row.id)} cell={@cell} />
    """
  end

  attr(:cell, :map, required: true)

  def cell_value(assigns) do
    ~H"""
    <span :if={@cell.format == :badge} class={Theme.slot(:badge, :base, variant: :soft)}>{@cell.value}</span>
    <span :if={@cell.format != :badge} class={cell_content_class(@cell)}>{@cell.display}</span>
    """
  end

  attr(:row, :map, required: true)
  attr(:actions, :list, required: true)
  attr(:env, :map, required: true)

  def row_actions(assigns) do
    ~H"""
    <div class={Theme.slot(:table, :action_group)}>
      <%= for action <- @actions, action_allowed?(@env.context, action, @row.source) do %>
        <.link :if={action.name == :edit && @row.id && form_enabled?(@env.context.resource)} patch={resource_edit_path(@env.base_path, @env.context.resource, @row.id)} class={Theme.slot(:button, :base, variant: :ghost, size: :xs)}>
          {action_label(action)}
        </.link>
        <button :if={action.name != :edit || !form_enabled?(@env.context.resource)} type="button" class={Theme.slot(:button, :base, variant: :ghost, size: :xs)} phx-click="incant:event" phx-value-op="row_action" phx-value-target={action.name} phx-value-value={@row.id} data-confirm={confirm_message(action)}>
          {action_label(action)}
        </button>
      <% end %>
    </div>
    """
  end

  def pagination(%{pagination: %{total: total}} = assigns) when total > 0 do
    ~H"""
    <div class={Theme.slot(:table, :pagination)}>
      <div>Page {@pagination.page} of {@pagination.total_pages} · {@pagination.total} rows</div>
      <div class={Theme.slot(:table, :pagination_actions)}>
        <button type="button" phx-click="incant:event" phx-value-op="paginate" phx-value-value={@pagination.page - 1} disabled={@pagination.page <= 1} class={Theme.slot(:button, :base, variant: :outline, size: :xs)}>Previous</button>
        <button type="button" phx-click="incant:event" phx-value-op="paginate" phx-value-value={@pagination.page + 1} disabled={@pagination.page >= @pagination.total_pages} class={Theme.slot(:button, :base, variant: :outline, size: :xs)}>Next</button>
      </div>
    </div>
    """
  end

  def pagination(assigns) do
    ~H"""
    """
  end

  defp selected?(table, row_id), do: to_string(row_id) in table.selection.selected_ids
  defp selected_count(table), do: length(table.selection.selected_ids)

  defp empty_colspan(table) do
    length(table.columns) + action_column_count(table) + selection_column_count(table)
  end

  defp action_column_count(%{row_actions: []}), do: 0
  defp action_column_count(_table), do: 1

  defp selection_column_count(%{selection: %{enabled: true}}), do: 1
  defp selection_column_count(_table), do: 0
end
