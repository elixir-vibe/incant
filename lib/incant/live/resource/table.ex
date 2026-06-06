defmodule Incant.Live.Resource.Table do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  alias Incant.Live.Authorization

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:resource, context.resource)
      |> assign(:rows, context.rows)
      |> assign(:table_state, context.table_state)

    ~H"""
    <.card class="overflow-hidden">
      <table class="min-w-full text-sm">
        <thead class="border-b border-[var(--incant-border)] bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]">
          <tr>
            <th :for={column <- @resource.table.columns} class="h-8 px-3 font-medium">
              <button type="button" phx-click="sort" phx-value-column={column.name} class="inline-flex items-center gap-1 rounded px-1 py-0.5 hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]">
                {column.name}
                <span :if={sort_column(@table_state.sort) == to_string(column.name)}>{sort_direction(@table_state.sort)}</span>
              </button>
            </th>
            <th :if={@resource.table.actions != []} class="h-8 px-3 text-right font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-[var(--incant-border-muted)]">
          <tr :if={@rows == []}>
            <td colspan={length(@resource.table.columns)} class="px-3 py-8 text-center text-sm text-[var(--incant-text-muted)]">
              No rows. Add a resource data callback or loosen the current filters.
            </td>
          </tr>
          <tr :for={row <- @rows} class="h-9 hover:bg-[var(--incant-bg-muted)]">
            <td :for={column <- @resource.table.columns} class={cell_class(column)}>
              <.cell context={@context} row={row} column={column} />
            </td>
            <td :if={@resource.table.actions != []} class="px-3 py-1.5 text-right">
              <.actions context={@context} row={row} />
            </td>
          </tr>
        </tbody>
      </table>
      <.pagination context={@context} />
    </.card>
    """
  end

  attr(:context, Incant.Live.Context, required: true)

  def pagination(%{context: %{pagination: %{total: total}}} = assigns) when total > 0 do
    assigns = assign(assigns, :pagination, assigns.context.pagination)

    ~H"""
    <div class="flex h-10 items-center justify-between gap-3 border-t border-[var(--incant-border)] px-3 text-xs text-[var(--incant-text-muted)]">
      <div>
        Page {@pagination.page} of {@pagination.total_pages} · {@pagination.total} rows
      </div>
      <div class="flex items-center gap-1">
        <button type="button" phx-click="page" phx-value-page={@pagination.page - 1} disabled={@pagination.page <= 1} class="rounded-md border border-[var(--incant-border)] px-2 py-1 disabled:opacity-40 hover:bg-[var(--incant-bg-accented)]">Previous</button>
        <button type="button" phx-click="page" phx-value-page={@pagination.page + 1} disabled={@pagination.page >= @pagination.total_pages} class="rounded-md border border-[var(--incant-border)] px-2 py-1 disabled:opacity-40 hover:bg-[var(--incant-bg-accented)]">Next</button>
      </div>
    </div>
    """
  end

  def pagination(assigns) do
    ~H"""
    """
  end

  attr(:context, Incant.Live.Context, required: true)
  attr(:row, :any, required: true)

  def actions(assigns) do
    assigns =
      assigns
      |> assign(:resource, assigns.context.resource)
      |> assign(:base_path, assigns.context.base_path)
      |> assign(:row_id, Incant.Live.Rows.id(assigns.row))

    ~H"""
    <div class="inline-flex items-center gap-1">
      <%= for action <- @resource.table.actions, action_allowed?(@context, action, @row) do %>
        <.primary_link :if={action.name == :edit && @row_id && form_enabled?(@resource)} patch={resource_edit_path(@base_path, @resource, @row_id)} class={action_class(action)}>
          {action_label(action)}
        </.primary_link>
        <button
          :if={action.name != :edit || !form_enabled?(@resource)}
          type="button"
          class={action_class(action)}
          phx-click="row_action"
          phx-value-action={action.name}
          phx-value-id={@row_id}
          data-confirm={action.opts[:confirm] && "Are you sure?"}
        >
          {action_label(action)}
        </button>
      <% end %>
    </div>
    """
  end

  attr(:context, Incant.Live.Context, required: true)
  attr(:row, :any, required: true)
  attr(:column, Incant.Table.Column, required: true)

  def cell(assigns) do
    assigns =
      assigns
      |> assign(:resource, assigns.context.resource)
      |> assign(:base_path, assigns.context.base_path)
      |> assign(:value, Incant.Live.Rows.field(assigns.row, assigns.column.name))
      |> assign(:row_id, Incant.Live.Rows.id(assigns.row))

    ~H"""
    <.primary_link :if={detail_link?(@context, @column, @row, @row_id)} patch={resource_detail_path(@base_path, @resource, @row_id)}>
      <.cell_value row={@row} column={@column} value={@value} />
    </.primary_link>
    <.cell_value :if={!detail_link?(@context, @column, @row, @row_id)} row={@row} column={@column} value={@value} />
    """
  end

  attr(:row, :any, required: true)
  attr(:column, Incant.Table.Column, required: true)
  attr(:value, :any, required: true)

  def cell_value(assigns) do
    assigns =
      assign(assigns, :rendered, render_cell_value(assigns.row, assigns.column, assigns.value))

    ~H"""
    <.badge :if={@column.opts[:as] == :badge} tone={:primary}>{@value}</.badge>
    <span :if={@column.opts[:as] != :badge}>{@rendered}</span>
    """
  end

  defp render_cell_value(row, column, value) do
    case column.opts[:render] do
      nil -> Incant.Live.Format.value(value, column.opts[:format])
      render -> Incant.Callback.call(render, value, row)
    end
  end

  defp detail_link?(context, column, row, row_id) do
    column.opts[:link] && row_id &&
      Authorization.allowed?(
        context.admin,
        :view_row,
        context.actor,
        authorization_context(context, row)
      )
  end

  defp action_allowed?(context, %{name: :edit}, row) do
    if form_enabled?(context.resource) do
      Authorization.allowed?(
        context.admin,
        :edit,
        context.actor,
        authorization_context(context, row)
      )
    else
      Authorization.allowed?(
        context.admin,
        :run_action,
        context.actor,
        authorization_context(context, row, %{action: :edit})
      )
    end
  end

  defp action_allowed?(context, action, row) do
    Authorization.allowed?(
      context.admin,
      :run_action,
      context.actor,
      authorization_context(context, row, %{action: action.name})
    )
  end

  defp authorization_context(context, row, extra \\ %{}) do
    context
    |> Map.from_struct()
    |> Map.merge(%{row: row})
    |> Map.merge(extra)
  end

  defp form_enabled?(resource), do: not is_nil(resource.repo) and not is_nil(resource.changeset)
  defp action_label(action), do: action.opts[:label] || humanize(action.name)

  defp action_class(action) do
    [
      "rounded-md px-1.5 py-1 text-xs transition",
      action.opts[:tone] == :danger &&
        "text-[var(--incant-error)] hover:bg-[color-mix(in_oklab,var(--incant-error)_12%,transparent)]",
      action.opts[:tone] != :danger &&
        "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
    ]
  end

  defp sort_column("-" <> column), do: column
  defp sort_column(column), do: column

  defp sort_direction("-" <> _column), do: "↓"
  defp sort_direction(_column), do: "↑"

  defp cell_class(column) do
    align = column.opts[:align]

    [
      "px-3 py-1.5 text-[var(--incant-text-toned)]",
      align == :right && "text-right tabular-nums"
    ]
  end

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
