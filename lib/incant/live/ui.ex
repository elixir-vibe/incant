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

  attr(:class, :any, default: nil)
  attr(:options, :list, default: [])
  attr(:value, :any, default: nil)
  attr(:prompt, :string, default: nil)
  attr(:rest, :global, include: ~w(name multiple))

  def select(assigns) do
    assigns = assign(assigns, :values, selected_values(assigns.value))

    ~H"""
    <select
      {@rest}
      class={[
        "rounded-xl border border-[var(--incant-border)] bg-[var(--incant-bg-muted)] px-3 py-2 text-sm text-[var(--incant-text-highlighted)] outline-none focus:border-[var(--incant-primary)]",
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

  def badge_html(value) do
    escaped = value |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    Phoenix.HTML.raw(
      ~s|<span class="rounded-full bg-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)] px-2 py-1 text-xs text-[var(--incant-primary)]">#{escaped}</span>|
    )
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

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
