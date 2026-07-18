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
              <button
                :if={table_filters_active?(@env.context.table_state)}
                type="button"
                class={Theme.slot(:table, :empty_action)}
                phx-click="incant:event"
                phx-value-op="filter_clear"
                phx-value-target="all"
              >
                Clear all filters
              </button>
              <p :if={@env.debug} class={Theme.slot(:table, :empty_hint)}>
                Developer hint: verify the resource index callback, filters, and query configuration.
              </p>
            </td>
          </tr>
          <tr :for={row <- @table.rows} class={row_class(@env.context, @table, row)}>
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
            <td :for={{cell, index} <- Enum.with_index(row.cells)} class={cell_class(cell)} title={cell_title(cell)}>
              <.table_cell cell={cell} row={row} env={@env} detail_link={detail_link_cell?(row.cells, index)} />
            </td>
            <td :if={@table.row_actions != []} class={Theme.slot(:table, :actions)}>
              <.row_actions row={row} actions={row.actions || @table.row_actions} env={@env} />
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
        <.table_action_button
          :for={action <- @table.bulk_actions}
          action={action}
          op="bulk_action"
          disabled={selected_count(@table) == 0}
        />
      </div>
      <div class={Theme.slot(:table, :toolbar_group)}>
        <.table_action_button
          :for={action <- @table.page_actions}
          action={action}
          op="page_action"
        />
      </div>
    </div>
    """
  end

  attr(:action, :map, required: true)
  attr(:op, :string, required: true)
  attr(:value, :any, default: nil)
  attr(:disabled, :boolean, default: false)
  attr(:variant, :atom, default: :outline)

  def table_action_button(assigns) do
    ~H"""
    <button
      type="button"
      class={Theme.slot(:button, :base, variant: @variant, size: :xs)}
      phx-click="incant:event"
      phx-value-op={@op}
      phx-value-target={@action.name}
      phx-value-value={@value}
      disabled={@disabled}
      data-incant-confirm={confirm_payload(@action)}
      phx-disable-with={action_label(@action) <> "…"}
    >
      {action_label(@action)}
    </button>
    """
  end

  attr(:cell, :map, required: true)
  attr(:row, :map, required: true)
  attr(:env, :map, required: true)
  attr(:detail_link, :boolean, default: false)

  def table_cell(assigns) do
    ~H"""
    <.link :if={@detail_link && row_detail_link?(@env.context, @row.source, @row.id) && @row.detail} patch={resource_detail_path(@env.base_path, @env.context.resource, @row.id)} class={Theme.slot(:table, :link)}>
      <.cell_value cell={@cell} />
    </.link>
    <.cell_value :if={!(@detail_link && row_detail_link?(@env.context, @row.source, @row.id) && @row.detail)} cell={@cell} />
    """
  end

  attr(:cell, :map, required: true)

  def cell_value(assigns) do
    ~H"""
    <span :if={cell_sensitive?(@cell)} class={Theme.slot(:badge, :base, variant: :outline)}>
      {redacted_cell_display()}
    </span>
    <span :if={!cell_sensitive?(@cell) && boolean_cell?(@cell)} class={Theme.slot(:table, :boolean, value: boolean_value?(@cell))}>
      {@cell.display}
    </span>
    <span :if={!cell_sensitive?(@cell) && !boolean_cell?(@cell) && @cell.format == :badge} class={Theme.slot(:badge, :base, variant: :soft)}>{@cell.value}</span>
    <span :if={!cell_sensitive?(@cell) && !boolean_cell?(@cell) && @cell.format != :badge} class={cell_content_class(@cell)}>{@cell.display}</span>
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
        <.table_action_button
          :if={action.name != :edit || !form_enabled?(@env.context.resource)}
          action={action}
          op="row_action"
          value={@row.id}
          variant={:ghost}
        />
      <% end %>
    </div>
    """
  end

  attr(:pagination, :map, required: true)

  def page_size_control(assigns) do
    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-change="incant:event" phx-value-op="filter_commit">
      <label class={Theme.slot(:table, :page_size)}>
        <span>Rows</span>
        <select name="table[page_size]" aria-label="Rows per page" class={Theme.slot(:table, :page_size_select)}>
          <option :for={size <- [10, 25, 50, 100]} value={size} selected={size == @pagination.page_size}>{size}</option>
        </select>
      </label>
    </.form>
    """
  end

  attr(:pagination, :map, required: true)

  def page_jump_control(assigns) do
    ~H"""
    <.form
      :let={_form}
      for={%{}}
      phx-submit="incant:event"
      phx-value-op="paginate"
      class={Theme.slot(:table, :page_jump)}
    >
      <label for="incant-table-page">Page</label>
      <input
        id="incant-table-page"
        name="page"
        type="number"
        inputmode="numeric"
        min="1"
        max={@pagination.total_pages}
        value={@pagination.page}
        aria-label="Page number"
        class={Theme.slot(:table, :page_input)}
      />
      <span>of {@pagination.total_pages}</span>
    </.form>
    """
  end

  attr(:value, :any, required: true)
  attr(:disabled, :boolean, required: true)
  attr(:label, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def pagination_button(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="incant:event"
      phx-value-op="paginate"
      phx-value-value={@value}
      disabled={@disabled}
      aria-label={@label}
      class={[Theme.slot(:button, :base, variant: :outline, size: :xs), @class]}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  def pagination(%{pagination: %{total: total}} = assigns) when total > 0 do
    ~H"""
    <div class={Theme.slot(:table, :pagination)}>
      <div>{pagination_range(@pagination)}</div>
      <div class={Theme.slot(:table, :pagination_actions)}>
        <.page_size_control pagination={@pagination} />
        <.pagination_button
          value="1"
          disabled={@pagination.page <= 1}
          label="First page"
          class="hidden sm:inline-flex"
        >«</.pagination_button>
        <.pagination_button
          value={@pagination.page - 1}
          disabled={@pagination.page <= 1}
          label="Previous page"
        >‹</.pagination_button>
        <.page_jump_control pagination={@pagination} />
        <.pagination_button
          value={@pagination.page + 1}
          disabled={@pagination.page >= @pagination.total_pages}
          label="Next page"
        >›</.pagination_button>
        <.pagination_button
          value={@pagination.total_pages}
          disabled={@pagination.page >= @pagination.total_pages}
          label="Last page"
          class="hidden sm:inline-flex"
        >»</.pagination_button>
      </div>
    </div>
    """
  end

  def pagination(assigns) do
    ~H"""
    """
  end

  defp table_filters_active?(table_state) do
    Map.get(table_state, :filters, %{}) != %{} or
      Map.get(table_state, :search, "") not in [nil, ""]
  end

  defp detail_link_cell?(cells, index) do
    preferred_index = Enum.find_index(cells, &cell_link?/1) || 0
    index == preferred_index
  end

  defp cell_link?(%{source: %{opts: opts}}) when is_list(opts),
    do: Keyword.get(opts, :link, false)

  defp cell_link?(%{source: %{opts: opts}}) when is_map(opts),
    do: Map.get(opts, :link, Map.get(opts, "link", false))

  defp cell_link?(_cell), do: false

  defp row_class(_context, table, _row), do: Theme.slot(:table, :row, density: table.density)

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
