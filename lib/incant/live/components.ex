defmodule Incant.Live.Components do
  @moduledoc """
  Shared Incant LiveView components for admin surfaces.
  """

  use Phoenix.Component

  attr(:class, :any, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div {@rest} class={["rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:tone, :atom, default: :neutral)
  slot(:inner_block, required: true)

  def badge(assigns) do
    ~H"""
    <span class={[badge_class(@tone), @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def pill(assigns) do
    ~H"""
    <span class={["inline-flex h-5 items-center rounded-md border border-[var(--incant-border)] px-1.5 text-[11px] leading-none text-[var(--incant-text-muted)]", @class]}>
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr(:patch, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def primary_link(assigns) do
    ~H"""
    <.link patch={@patch} class={["font-medium text-[var(--incant-text-highlighted)] hover:underline", @class]}>
      {render_slot(@inner_block)}
    </.link>
    """
  end

  attr(:patch, :string, required: true)
  attr(:class, :any, default: nil)
  slot(:inner_block, required: true)

  def back_link(assigns) do
    ~H"""
    <.primary_link patch={@patch} class={["text-sm", @class]}>
      {render_slot(@inner_block)}
    </.primary_link>
    """
  end

  attr(:class, :any, default: nil)
  attr(:rest, :global, include: ~w(type name value placeholder readonly step))

  def input(assigns) do
    ~H"""
    <input
      {@rest}
      class={[
        "h-8 rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] transition focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]", 
        @class
      ]}
    />
    """
  end

  attr(:class, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:value, :any, default: nil)
  attr(:prompt, :string, default: nil)
  attr(:rest, :global, include: ~w(name multiple disabled))

  def select(assigns) do
    assigns = assign(assigns, :values, selected_values(assigns.value))

    ~H"""
    <select
      {@rest}
      class={[
        "h-8 rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm text-[var(--incant-text-highlighted)] outline-none transition focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]", 
        @class
      ]}
    >
      <option :if={@prompt} value="">{@prompt}</option>
      <option :for={{label, value} <- option_pairs(@options)} value={value} selected={to_string(value) in @values}>
        {label}
      </option>
    </select>
    """
  end

  defp badge_class(:primary) do
    "inline-flex h-5 items-center rounded-md bg-[var(--incant-bg-muted)] px-1.5 text-[11px] font-medium leading-none text-[var(--incant-text-toned)]"
  end

  defp badge_class(_tone) do
    "inline-flex h-5 items-center rounded-md border border-[var(--incant-border)] px-1.5 text-[11px] leading-none text-[var(--incant-text-muted)]"
  end

  defp selected_values(nil), do: []
  defp selected_values(values) when is_list(values), do: Enum.map(values, &to_string/1)
  defp selected_values(value), do: [to_string(value)]

  defp option_pairs(options) do
    Enum.map(options, fn
      {label, value} -> {label, value}
      value -> {humanize(value), value}
    end)
  end

  defp humanize(value), do: Incant.Naming.label(value)
end
