defmodule Incant.Live.ResourceComponents do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:rows, :list, default: [])
  attr(:selected_row, :any, default: nil)
  attr(:detail_id, :string, default: nil)
  attr(:base_path, :string, required: true)
  attr(:table_state, :map, default: %{})

  def resource_view(assigns) do
    ~H"""
    <section class="space-y-6">
      <.card class="p-5">
        <p class="text-sm text-[var(--incant-text-muted)]">Resource</p>
        <h2 class="mt-1 text-3xl font-semibold tracking-tight">{short_module(@resource.module)}</h2>
        <p class="mt-2 font-mono text-sm text-[var(--incant-text-muted)]">schema {inspect(@resource.schema)} · repo {inspect(@resource.repo)}</p>

        <.form :let={_form} for={%{}} as={:table} phx-change="table_state" class="mt-5 grid gap-3 md:grid-cols-3">
          <.input
            :if={@resource.table.search}
            type="search"
            name="table[search]"
            value={@table_state.search}
            placeholder="Search"
          />
          <.filter_control
            :for={filter <- @resource.table.filters}
            filter={filter}
            value={Map.get(@table_state.filters, to_string(filter.name), "")}
          />
        </.form>
      </.card>

      <.card :if={@selected_row} class="p-5">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-sm text-[var(--incant-text-muted)]">Detail</p>
            <h3 class="mt-1 text-xl font-semibold tracking-tight">{Incant.Live.Rows.title(@selected_row, @resource)}</h3>
          </div>
          <.back_link patch={resource_path(@base_path, @resource)}>
            Back to list
          </.back_link>
        </div>
        <dl class="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          <div :for={column <- @resource.table.columns} class="rounded-xl bg-[var(--incant-bg-muted)] p-3">
            <dt class="text-xs uppercase tracking-wide text-[var(--incant-text-muted)]">{column_label(column)}</dt>
            <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">
              <.cell_value row={@selected_row} column={column} value={Incant.Live.Rows.field(@selected_row, column.name)} />
            </dd>
          </div>
          <div :for={{key, value} <- extra_fields(@selected_row, @resource)} class="rounded-xl bg-[var(--incant-bg-muted)] p-3">
            <dt class="text-xs uppercase tracking-wide text-[var(--incant-text-muted)]">{key}</dt>
            <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">{value}</dd>
          </div>
        </dl>
      </.card>

      <.card :if={@detail_id && !@selected_row} class="p-8 text-center">
        <p class="text-sm text-[var(--incant-text-muted)]">Record not found</p>
        <h3 class="mt-2 text-xl font-semibold tracking-tight">No resource row matches {@detail_id}</h3>
        <div class="mt-4">
          <.back_link patch={resource_path(@base_path, @resource)}>
            Back to list
          </.back_link>
        </div>
      </.card>

      <.card class="overflow-hidden">
        <table class="min-w-full divide-y divide-[var(--incant-border)] text-sm">
          <thead class="bg-[var(--incant-bg-accented)] text-left text-xs uppercase tracking-wider text-[var(--incant-text-muted)]">
            <tr>
              <th :for={column <- @resource.table.columns} class="px-4 py-3 font-medium">
                <button type="button" phx-click="sort" phx-value-column={column.name} class="inline-flex items-center gap-1 hover:text-[var(--incant-text-highlighted)]">
                  {column.name}
                  <span :if={sort_column(@table_state.sort) == to_string(column.name)}>{sort_direction(@table_state.sort)}</span>
                </button>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-[var(--incant-border)]">
            <tr :if={@rows == []}>
              <td colspan={length(@resource.table.columns)} class="px-4 py-10 text-center text-[var(--incant-text-muted)]">
                No rows. Add a resource data callback or loosen the current filters.
              </td>
            </tr>
            <tr :for={row <- @rows} class="hover:bg-[var(--incant-bg-accented)]">
              <td :for={column <- @resource.table.columns} class={cell_class(column)}>
                <.resource_cell row={row} column={column} resource={@resource} base_path={@base_path} />
              </td>
            </tr>
          </tbody>
        </table>
      </.card>
    </section>
    """
  end

  attr(:filter, Incant.Table.Filter, required: true)
  attr(:value, :any, default: nil)

  def filter_control(assigns) do
    ~H"""
    {Incant.Filter.control(@filter, @value, assigns)}
    """
  end

  attr(:row, :any, required: true)
  attr(:column, Incant.Table.Column, required: true)
  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:base_path, :string, required: true)

  def resource_cell(assigns) do
    assigns =
      assigns
      |> assign(:value, Incant.Live.Rows.field(assigns.row, assigns.column.name))
      |> assign(:row_id, Incant.Live.Rows.id(assigns.row))

    ~H"""
    <.primary_link :if={@column.opts[:link] && @row_id} patch={resource_detail_path(@base_path, @resource, @row_id)}>
      <.cell_value row={@row} column={@column} value={@value} />
    </.primary_link>
    <.cell_value :if={!@column.opts[:link] || !@row_id} row={@row} column={@column} value={@value} />
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
      nil -> format_value(value, column.opts[:format])
      render -> Incant.Callback.call(render, value, row)
    end
  end

  defp extra_fields(row, resource) do
    column_names = MapSet.new(Enum.map(resource.table.columns, & &1.name))

    row
    |> Incant.Live.Rows.fields()
    |> Enum.reject(fn {key, _value} -> key in column_names or key == :id end)
  end

  defp column_label(column) do
    column.opts[:label] || humanize(column.name)
  end

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end

  defp sort_column("-" <> column), do: column
  defp sort_column(column), do: column

  defp sort_direction("-" <> _column), do: "↓"
  defp sort_direction(_column), do: "↑"

  defp cell_class(column) do
    align = column.opts[:align]

    [
      "px-4 py-3 text-[var(--incant-text-toned)]",
      align == :right && "text-right tabular-nums"
    ]
  end

  defp format_value(value, :money), do: format_currency(value)
  defp format_value(value, :currency), do: format_currency(value)
  defp format_value(value, :percent) when is_number(value), do: "#{Float.round(value * 100, 2)}%"
  defp format_value(value, :relative), do: to_string(value)
  defp format_value(value, _format), do: to_string(value)

  defp format_currency(value) when is_integer(value), do: "$#{value}"

  defp format_currency(value) when is_float(value),
    do: "$#{:erlang.float_to_binary(value, decimals: 2)}"

  defp format_currency(value), do: to_string(value)

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
