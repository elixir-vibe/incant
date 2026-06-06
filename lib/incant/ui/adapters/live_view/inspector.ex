defmodule Incant.UI.Adapters.LiveView.Inspector do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Routes

  alias Incant.UI.Regions.Inspector

  attr(:inspector, Inspector, required: true)
  attr(:env, :map, required: true)

  def inspector(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <div class="flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-3 py-2.5">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Detail</p>
          <h3 class="mt-1 text-base font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{@inspector.title}</h3>
        </div>
        <.link patch={resource_path(@env.base_path, @env.context.resource)} class="text-xs font-medium text-[var(--incant-text-highlighted)] hover:underline">Back to list</.link>
      </div>
      <dl class="grid divide-y divide-[var(--incant-border-muted)] md:grid-cols-2 md:divide-x md:divide-y-0 xl:grid-cols-3">
        <div :for={field <- @inspector.fields} class="px-3 py-2.5">
          <dt class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{field.label}</dt>
          <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">{field.display}</dd>
        </div>
      </dl>
    </div>
    """
  end
end
