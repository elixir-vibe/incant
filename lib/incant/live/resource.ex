defmodule Incant.Live.Resource do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  alias Incant.Live.Resource.{Form, Table}

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:resource, context.resource)
      |> assign(:rows, context.rows)
      |> assign(:selected_row, context.selected_row)
      |> assign(:detail_id, context.detail_id)
      |> assign(:base_path, context.base_path)
      |> assign(:form_mode, context.form_mode)
      |> assign(:form_record, context.form_record)
      |> assign(:form_changeset, context.form_changeset)
      |> assign(:table_state, context.table_state)

    ~H"""
    <section class="space-y-6">
      <.card class="p-5">
        <p class="text-sm text-[var(--incant-text-muted)]">Resource</p>
        <h2 class="mt-1 text-3xl font-semibold tracking-tight">{short_module(@resource.module)}</h2>
        <div class="flex items-start justify-between gap-4">
          <p class="mt-2 font-mono text-sm text-[var(--incant-text-muted)]">schema {inspect(@resource.schema)} · repo {inspect(@resource.repo)}</p>
          <.primary_link :if={form_enabled?(@resource)} patch={resource_new_path(@base_path, @resource)} class="text-sm">
            New
          </.primary_link>
        </div>

        <.form :let={_form} for={%{}} as={:table} phx-change="table_state" class="mt-5 grid gap-3 md:grid-cols-3">
          <.input
            :if={@resource.table.search}
            type="search"
            name="table[search]"
            value={@table_state.search}
            placeholder="Search"
          />
          <.filter
            :for={filter <- @resource.table.filters}
            filter={filter}
            value={Map.get(@table_state.filters, to_string(filter.name), "")}
          />
        </.form>
      </.card>

      <Form.view :if={@form_mode} resource={@resource} record={@form_record} changeset={@form_changeset} mode={@form_mode} base_path={@base_path} />

      <.card :if={!@form_mode && @selected_row} class="p-5">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-sm text-[var(--incant-text-muted)]">Detail</p>
            <h3 class="mt-1 text-xl font-semibold tracking-tight">{Incant.Live.Rows.title(@selected_row, @resource)}</h3>
          </div>
          <div class="flex items-center gap-2">
            <Table.actions context={@context} row={@selected_row} />
            <.back_link patch={resource_path(@base_path, @resource)}>
              Back to list
            </.back_link>
          </div>
        </div>
        <dl class="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          <div :for={column <- @resource.table.columns} class="rounded-xl bg-[var(--incant-bg-muted)] p-3">
            <dt class="text-xs uppercase tracking-wide text-[var(--incant-text-muted)]">{column_label(column)}</dt>
            <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">
              <Table.cell_value row={@selected_row} column={column} value={Incant.Live.Rows.field(@selected_row, column.name)} />
            </dd>
          </div>
          <div :for={{key, value} <- extra_fields(@selected_row, @resource)} class="rounded-xl bg-[var(--incant-bg-muted)] p-3">
            <dt class="text-xs uppercase tracking-wide text-[var(--incant-text-muted)]">{key}</dt>
            <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">{value}</dd>
          </div>
        </dl>
      </.card>

      <.card :if={!@form_mode && @detail_id && !@selected_row} class="p-8 text-center">
        <p class="text-sm text-[var(--incant-text-muted)]">Record not found</p>
        <h3 class="mt-2 text-xl font-semibold tracking-tight">No resource row matches {@detail_id}</h3>
        <div class="mt-4">
          <.back_link patch={resource_path(@base_path, @resource)}>
            Back to list
          </.back_link>
        </div>
      </.card>

      <Table.view context={@context} />
    </section>
    """
  end

  attr(:filter, Incant.Table.Filter, required: true)
  attr(:value, :any, default: nil)

  def filter(assigns) do
    ~H"""
    {Incant.Filter.control(@filter, @value, assigns)}
    """
  end

  defp form_enabled?(resource), do: not is_nil(resource.repo) and not is_nil(resource.changeset)

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

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
