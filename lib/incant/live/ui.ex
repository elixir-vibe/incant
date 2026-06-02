defmodule Incant.Live.UI do
  @moduledoc """
  Shared Incant LiveView components for admin surfaces.
  """

  use Phoenix.Component

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div class={["rounded-2xl border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def pill(assigns) do
    ~H"""
    <span class={["rounded-full border border-[var(--incant-border)] px-3 py-1 text-xs text-[var(--incant-text-muted)]", @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(type name value placeholder))

  def text_input(assigns) do
    ~H"""
    <input
      {@rest}
      class={[
        "rounded-xl border border-[var(--incant-border)] bg-[var(--incant-bg-muted)] px-3 py-2 text-sm text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] focus:border-[var(--incant-primary)]",
        @class
      ]}
    />
    """
  end

  def badge_html(value) do
    escaped = value |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s|<span class="rounded-full bg-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)] px-2 py-1 text-xs text-[var(--incant-primary)]">#{escaped}</span>|
    )
  end
end
