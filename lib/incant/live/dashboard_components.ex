defmodule Incant.Live.DashboardComponents do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components

  attr(:dashboard, Incant.Dashboard.Metadata, required: true)
  attr(:widget_values, :map, default: %{})

  def dashboard_view(assigns) do
    ~H"""
    <section class="space-y-6">
      <.card class="flex flex-col gap-4 p-5">
        <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <p class="text-sm text-[var(--incant-text-muted)]">Dashboard</p>
            <h2 class="text-3xl font-semibold tracking-tight">{@dashboard.title}</h2>
          </div>
          <div class="font-mono text-xs text-[var(--incant-text-muted)]">{inspect(@dashboard.grid)}</div>
        </div>

        <div class="flex flex-wrap gap-2">
          <.pill :for={variable <- @dashboard.variables} class="bg-[var(--incant-bg-accented)] text-[var(--incant-text-toned)]">
            {variable.name}: {variable.type}
          </.pill>
        </div>
      </.card>

      <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <.card :for={widget <- @dashboard.widgets} class="p-5 shadow-2xl shadow-[color-mix(in_oklab,var(--incant-bg-inverted)_8%,transparent)]">
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-sm capitalize text-[var(--incant-text-muted)]">{widget.type}</p>
              <h3 class="mt-1 font-mono text-lg font-semibold">{widget.id}</h3>
            </div>
            <.pill class="border-0 bg-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)] px-2.5 text-[var(--incant-primary)]">span {widget.opts[:span] || "auto"}</.pill>
          </div>
          <div :if={Map.has_key?(@widget_values, widget.id)} class="mt-5 text-3xl font-semibold tracking-tight">
            {format_widget_value(@widget_values[widget.id], widget)}
          </div>
          <pre :if={!Map.has_key?(@widget_values, widget.id)} class="mt-5 overflow-auto rounded-xl bg-[var(--incant-bg-muted)] p-3 text-xs text-[var(--incant-text-muted)]"><%= inspect(widget.opts, pretty: true) %></pre>
        </.card>
      </div>
    </section>
    """
  end

  defp format_widget_value(value, widget), do: format_value(value, widget.opts[:format])

  defp format_value(value, :money), do: format_currency(value)
  defp format_value(value, :currency), do: format_currency(value)
  defp format_value(value, :percent) when is_number(value), do: "#{Float.round(value * 100, 2)}%"
  defp format_value(value, :relative), do: to_string(value)
  defp format_value(value, _format), do: to_string(value)

  defp format_currency(value) when is_integer(value), do: "$#{value}"

  defp format_currency(value) when is_float(value),
    do: "$#{:erlang.float_to_binary(value, decimals: 2)}"

  defp format_currency(value), do: to_string(value)
end
