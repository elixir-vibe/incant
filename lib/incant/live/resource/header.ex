defmodule Incant.Live.Resource.Header do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:resource, context.resource)
      |> assign(:base_path, context.base_path)
      |> assign(:table_state, context.table_state)

    ~H"""
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

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
