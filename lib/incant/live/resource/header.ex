defmodule Incant.Live.Resource.Header do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  alias Incant.Live.Authorization

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    resource = context.resource

    assigns =
      assigns
      |> assign(:resource, resource)
      |> assign(:base_path, context.base_path)
      |> assign(:table_state, context.table_state)
      |> assign(:metadata, metadata_items(resource))

    ~H"""
    <.card class="overflow-hidden">
      <div class="flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] px-3 py-2.5">
        <div class="min-w-0">
          <div class="flex items-center gap-2">
            <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Resource</p>
            <div class="flex flex-wrap gap-1.5 text-xs text-[var(--incant-text-muted)]">
              <.pill :for={{label, value} <- @metadata}>
                <span class="mr-1 font-medium uppercase">{label}</span>{value}
              </.pill>
            </div>
          </div>
          <h2 class="mt-1 truncate text-lg font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{short_module(@resource.module)}</h2>
        </div>
        <.primary_link :if={can_create?(@context)} patch={resource_new_path(@base_path, @resource)} class="rounded-md border border-[var(--incant-border)] px-2 py-1 text-xs hover:bg-[var(--incant-bg-accented)] hover:no-underline">
          New
        </.primary_link>
      </div>

      <.form :let={_form} for={%{}} as={:table} phx-change="table_state" class="grid gap-2 p-3 md:grid-cols-4">
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

  defp metadata_items(resource) do
    [
      {"schema", module_label(resource.schema)},
      {"repo", module_label(resource.repo)},
      {"data", callback_label(resource.data)}
    ]
    |> Enum.reject(fn {_label, value} -> is_nil(value) end)
  end

  defp module_label(nil), do: nil
  defp module_label(module) when is_atom(module), do: inspect(module)

  defp callback_label(nil), do: nil
  defp callback_label(callback) when is_function(callback), do: "callback"
  defp callback_label(callback), do: inspect(callback)

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
