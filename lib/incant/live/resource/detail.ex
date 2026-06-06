defmodule Incant.Live.Resource.Detail do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  alias Incant.Live.Resource.Table

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:resource, context.resource)
      |> assign(:selected_row, context.selected_row)
      |> assign(:detail_id, context.detail_id)
      |> assign(:base_path, context.base_path)
      |> assign(:form_mode, context.form_mode)

    ~H"""
    <.card :if={!@form_mode && @selected_row} class="overflow-hidden">
      <div class="flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-3 py-2.5">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Detail</p>
          <h3 class="mt-1 text-base font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{Incant.Live.Rows.title(@selected_row, @resource)}</h3>
        </div>
        <div class="flex items-center gap-2">
          <Table.actions context={@context} row={@selected_row} />
          <.back_link patch={resource_path(@base_path, @resource)} class="text-xs">
            Back to list
          </.back_link>
        </div>
      </div>
      <dl class="grid divide-y divide-[var(--incant-border-muted)] md:grid-cols-2 md:divide-x md:divide-y-0 xl:grid-cols-3">
        <div :for={column <- @resource.table.columns} class="px-3 py-2.5">
          <dt class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{column_label(column)}</dt>
          <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">
            <Table.cell_value row={@selected_row} column={column} value={Incant.Live.Rows.field(@selected_row, column.name)} />
          </dd>
        </div>
        <div :for={{key, value} <- extra_fields(@selected_row, @resource)} class="px-3 py-2.5">
          <dt class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{key}</dt>
          <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">{value}</dd>
        </div>
      </dl>
    </.card>

    <.card :if={!@form_mode && @detail_id && !@selected_row} class="p-6 text-center">
      <p class="text-sm text-[var(--incant-text-muted)]">Record not found</p>
      <h3 class="mt-2 text-xl font-semibold tracking-tight">No resource row matches {@detail_id}</h3>
      <div class="mt-4">
        <.back_link patch={resource_path(@base_path, @resource)}>
          Back to list
        </.back_link>
      </div>
    </.card>
    """
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
end
