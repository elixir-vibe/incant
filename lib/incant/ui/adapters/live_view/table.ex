defmodule Incant.UI.Adapters.LiveView.Table do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Routes
  import Incant.UI.Adapters.LiveView.Controls
  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Regions.{FilterBar, Table}

  attr(:table, Table, required: true)
  attr(:filter_bar, FilterBar, default: nil)
  attr(:env, :map, required: true)

  def table(assigns) do
    ~H"""
    <div class={Theme.slot(:panel, :root, kind: :table)}>
      <.table_filter_bar :if={@filter_bar} filter_bar={@filter_bar} env={@env} />
      <.table_toolbar table={@table} env={@env} />
      <div class={Theme.slot(:table, :viewport)}>
        <table class={Theme.slot(:table, :root)}>
        <thead class={Theme.slot(:table, :head)}>
          <tr>
            <th :if={@table.selection && @table.selection.enabled} class={Theme.slot(:table, :checkbox_cell)}>
              <input
                type="checkbox"
                class={Theme.slot(:table, :checkbox)}
                checked={all_selected?(@table)}
                aria-label="Select all rows on this page"
                phx-click="incant:event"
                phx-value-op="row_select_all"
              />
            </th>
            <th :for={column <- @table.columns} class={table_header_class(column)} aria-sort={sort_aria(@table.sort, column)}>
              <button :if={column.sortable} type="button" phx-click="incant:event" phx-value-op="sort" phx-value-target={column.id} class={table_sort_button_class(column)}>
                {column.label}
                <span :if={sort_column(@table.sort) == column.id} aria-hidden="true">{sort_direction(@table.sort)}</span>
              </button>
              <span :if={!column.sortable}>{column.label}</span>
            </th>
            <th :if={@table.row_actions != []} class={Theme.slot(:table, :header_cell, align: :right)}>Actions</th>
          </tr>
        </thead>
        <tbody class={Theme.slot(:table, :body)}>
          <tr :if={@table.rows == []}>
            <td colspan={empty_colspan(@table)} class={Theme.slot(:table, :empty)}>
              <div>{@table.empty_state}</div>
              <p :if={@env.debug} class={Theme.slot(:table, :empty_hint)}>
                Developer hint: verify the resource index callback, filters, and query configuration.
              </p>
            </td>
          </tr>
          <tr :for={row <- @table.rows} class={Theme.slot(:table, :row, density: @table.density)}>
            <td :if={@table.selection && @table.selection.enabled} class={Theme.slot(:table, :checkbox_cell)}>
              <input
                type="checkbox"
                class={Theme.slot(:table, :checkbox)}
                checked={selected?(@table, row.id)}
                aria-label={"Select row #{row.id}"}
                phx-click="incant:event"
                phx-value-op="row_select"
                phx-value-value={row.id}
              />
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
    <span :if={cell_sensitive?(@cell)} class={Theme.slot(:badge, :base, variant: :outline)}>
      {redacted_cell_display()}
    </span>
    <span :if={!cell_sensitive?(@cell) && @cell.format == :badge} class={Theme.slot(:badge, :base, variant: :soft)}>{@cell.value}</span>
    <span :if={!cell_sensitive?(@cell) && @cell.format != :badge} class={cell_content_class(@cell)}>{@cell.display}</span>
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
      <div>{pagination_range(@pagination)}</div>
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

  defp all_selected?(table) do
    table.rows != [] and Enum.all?(table.rows, &selected?(table, &1.id))
  end

  defp sort_aria(sort, column) do
    cond do
      not column.sortable -> nil
      sort == column.id -> "ascending"
      sort == "-#{column.id}" -> "descending"
      true -> "none"
    end
  end

  defp pagination_range(%{page: page, page_size: page_size, total: total}) do
    first = (page - 1) * page_size + 1
    last = min(page * page_size, total)
    "#{first}–#{last} of #{total}"
  end

  defp empty_colspan(table) do
    length(table.columns) + action_column_count(table) + selection_column_count(table)
  end

  defp action_column_count(%{row_actions: []}), do: 0
  defp action_column_count(_table), do: 1

  defp selection_column_count(%{selection: %{enabled: true}}), do: 1
  defp selection_column_count(_table), do: 0
end
