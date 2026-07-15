defmodule Incant.UI.Adapters.LiveView.Dashboard do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Regions.WidgetGrid

  attr(:grid, WidgetGrid, required: true)

  def widget_grid(assigns) do
    ~H"""
    <div class={Theme.slot(:widget_grid, :root)} style={widget_grid_style(@grid)}>
      <.widget :for={widget <- @grid.widgets} widget={widget} />
    </div>
    """
  end

  attr(:widget, :map, required: true)

  def widget(%{widget: %{type: :stat}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root, kind: :stat)} style={widget_style(@widget)} data-incant-widget data-incant-widget-kind="stat">
      <p class={Theme.slot(:widget, :stat_label)}>{@widget.title}</p>
      <div class={Theme.slot(:widget, :stat_value)}>
        <%= cond do %>
          <% @widget.error -> %>
            <span class={Theme.slot(:widget, :error)}>Unable to load widget.</span>
          <% @widget.loading -> %>
            <span class={Theme.slot(:widget, :message)}>Loading…</span>
          <% true -> %>
            {@widget.display || "—"}
        <% end %>
      </div>
      <p :if={is_number(@widget.delta)} class={stat_delta_class(@widget.delta)}>
        {stat_delta(@widget.delta)} vs previous
      </p>
    </div>
    """
  end

  def widget(%{widget: %{type: :timeseries}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)} data-incant-widget data-incant-widget-kind="timeseries">
      <div class={Theme.slot(:widget, :title_row)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>Timeseries</p>
          <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
        </div>
      </div>
      <.widget_message :if={@widget.error} tone={:error} message="Unable to load widget." />
      <.widget_message :if={!@widget.error && @widget.loading} message="Loading…" />
      <.widget_message :if={!@widget.error && !@widget.loading && chart_points(@widget.value) == []} message="No data to display." />
      <div :if={!@widget.error && !@widget.loading && chart_points(@widget.value) != []} class={Theme.slot(:widget, :chart)}>
        <svg viewBox="0 0 100 48" preserveAspectRatio="none" class={Theme.slot(:widget, :chart_svg)} role="img" aria-label={"#{@widget.title} bars"}>
          <rect :for={bar <- chart_bars(@widget.value)} x={bar.x} y={bar.y} width={bar.width} height={bar.height} rx="1.5" class={Theme.slot(:widget, :bar)}>
            <title>{bar.label}</title>
          </rect>
        </svg>
        <div class={Theme.slot(:widget, :chart_axis)}>
          <span>{chart_first_label(@widget.value)}</span>
          <span>{chart_last_label(@widget.value)}</span>
        </div>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :chart}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)} data-incant-widget data-incant-widget-kind="chart">
      <div class={Theme.slot(:widget, :title_row)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>{@widget.chart.type || "Chart"}</p>
          <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
        </div>
        <span :if={@widget.chart.dataset} class={Theme.slot(:badge, :base)}>{short_chart_dataset(@widget.chart.dataset)}</span>
      </div>
      <.widget_message :if={@widget.error} tone={:error} message="Unable to load widget." />
      <.widget_message :if={!@widget.error && @widget.loading} message="Loading…" />
      <.widget_message :if={!@widget.error && !@widget.loading && chart_points(@widget.value) == []} message="No data to display." />
      <div :if={!@widget.error && !@widget.loading && chart_points(@widget.value) != []} class={Theme.slot(:widget, :chart)}>
        <div class={Theme.slot(:widget, :chart_labels)}>
          <span>{Incant.Live.Format.value(chart_max(@widget.value), :number)}</span>
          <span>{Incant.Live.Format.value(chart_min(@widget.value), :number)}</span>
        </div>
        <svg viewBox="0 0 100 48" preserveAspectRatio="none" class={Theme.slot(:widget, :chart_svg)} role="img" aria-label={"#{@widget.title} line chart"}>
          <defs>
            <linearGradient id={"chart-gradient-#{@widget.id}"} x1="0" x2="0" y1="0" y2="1">
              <stop offset="0%" stop-color="var(--incant-primary)" stop-opacity="0.28" />
              <stop offset="100%" stop-color="var(--incant-primary)" stop-opacity="0" />
            </linearGradient>
          </defs>
          <polygon points={chart_area(@widget.value)} fill={"url(#chart-gradient-#{@widget.id})"} />
          <polyline points={chart_polyline(@widget.value)} fill="none" stroke="var(--incant-primary)" stroke-width="2" vector-effect="non-scaling-stroke" />
        </svg>
        <div class={Theme.slot(:widget, :chart_axis)}>
          <span>{chart_first_label(@widget.value)}</span>
          <span>{chart_last_label(@widget.value)}</span>
        </div>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :table}} = assigns) do
    rows = table_rows(assigns.widget.value)

    assigns =
      assigns
      |> assign(:rows, Enum.take(rows, table_preview_limit(assigns.widget)))
      |> assign(:total_rows, length(rows))

    ~H"""
    <div class={Theme.slot(:widget, :framed)} style={widget_style(@widget)} data-incant-widget data-incant-widget-kind="table">
      <div class={Theme.slot(:widget, :header)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>Table</p>
          <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
        </div>
      </div>
      <.widget_message :if={@widget.error} tone={:error} message="Unable to load widget." />
      <.widget_message :if={!@widget.error && @widget.loading} message="Loading…" />
      <.widget_message :if={!@widget.error && !@widget.loading && @rows == [] && table_columns(@widget) == []} message="No rows to display." />
      <div :if={!@widget.error && !@widget.loading && table_columns(@widget) != []} class={Theme.slot(:widget, :table_viewport)}>
        <table class={Theme.slot(:table, :root)}>
          <thead class={Theme.slot(:table, :head)}>
            <tr><th :for={column <- table_columns(@widget)} class={table_header_class(column)}>{table_column_label(column)}</th></tr>
          </thead>
          <tbody class={Theme.slot(:table, :body)}>
            <tr :if={@rows == []}><td colspan={length(table_columns(@widget))} class={Theme.slot(:table, :empty)}>No rows to display.</td></tr>
            <tr :for={row <- @rows} class={Theme.slot(:table, :row)}><td :for={column <- table_columns(@widget)} class={table_data_class(column)}>{table_cell_display(column, table_cell(row, column))}</td></tr>
          </tbody>
        </table>
      </div>
      <div :if={@total_rows > length(@rows)} class={Theme.slot(:widget, :table_footer)}>
        Showing {length(@rows)} of {@total_rows} rows
      </div>
    </div>
    """
  end

  def widget(assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)} data-incant-widget data-incant-widget-kind={@widget.type}>
      <p class={Theme.slot(:widget, :eyebrow)}>{@widget.type}</p>
      <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
    </div>
    """
  end

  attr(:message, :string, required: true)
  attr(:tone, :atom, default: :default)

  def widget_message(assigns) do
    ~H"""
    <p class={widget_message_class(@tone)}>{@message}</p>
    """
  end

  defp widget_message_class(:error), do: Theme.slot(:widget, :message_error)
  defp widget_message_class(_tone), do: Theme.slot(:widget, :message)

  defp table_preview_limit(%{source: %{opts: opts}}) when is_list(opts),
    do: Keyword.get(opts, :preview_rows, 10)

  defp table_preview_limit(%{source: %{opts: opts}}) when is_map(opts),
    do: Map.get(opts, :preview_rows, Map.get(opts, "preview_rows", 10))

  defp table_preview_limit(_widget), do: 10

  defp widget_grid_style(%{columns: columns}), do: "--incant-grid-columns: #{columns};"

  defp stat_delta(delta) do
    sign = if delta >= 0, do: "+", else: ""
    "#{sign}#{Float.round(delta * 100, 1)}%"
  end

  defp stat_delta_class(delta), do: Theme.slot(:widget, :stat_delta, positive: delta >= 0)
end
