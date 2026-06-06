defmodule Incant.Live.Resource.Header do
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
      |> assign(:base_path, context.base_path)
      |> assign(:table_state, context.table_state)

    ~H"""
    <.card class="overflow-hidden">
      <div :if={can_create?(@context)} class="flex min-h-9 items-center justify-end border-b border-[var(--incant-border-muted)] px-2 py-1.5">
        <.primary_link patch={resource_new_path(@base_path, @resource)} class="rounded-md border border-[var(--incant-border)] px-2 py-1 text-xs hover:bg-[var(--incant-bg-accented)] hover:no-underline">
          New
        </.primary_link>
      </div>

      <.form :let={_form} for={%{}} as={:table} phx-change="table_state" class="grid gap-2 p-2 md:grid-cols-[minmax(12rem,1fr)_minmax(10rem,1fr)_minmax(14rem,1fr)_8rem]">
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
        <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
          Rows
          <.select name="table[page_size]" value={@table_state.page_size} options={[10, 25, 50, 100]} />
        </label>
      </.form>
    </.card>
    """
  end

  attr(:filter, Incant.Table.Filter, required: true)
  attr(:value, :any, default: nil)

  def filter(assigns) do
    ~H"""
    {Incant.Filter.control(@filter, @value, assigns)}
    """
  end

  defp can_create?(context) do
    form_enabled?(context.resource) and
      Authorization.allowed?(context.admin, :create, context.actor, Map.from_struct(context))
  end

  defp form_enabled?(resource), do: not is_nil(resource.repo) and not is_nil(resource.changeset)
end
