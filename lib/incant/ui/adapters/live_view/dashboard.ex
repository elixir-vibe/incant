defmodule Incant.UI.Adapters.LiveView.Dashboard do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Regions.WidgetGrid

  attr(:grid, WidgetGrid, required: true)

  def widget_grid(assigns) do
    ~H"""
    <div class={Theme.slot(:widget_grid, :root)}>
      <.widget :for={widget <- @grid.widgets} widget={widget} />
    </div>
    """
  end

  attr(:widget, :map, required: true)

  def widget(%{widget: %{type: :stat}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)}>
      <p class={Theme.slot(:widget, :stat_label)}>{@widget.title}</p>
      <div class={Theme.slot(:widget, :stat_value)}>
        <%= if @widget.error do %>
          <span class={Theme.slot(:widget, :error)}>{@widget.error}</span>
        <% else %>
          {@widget.display || "—"}
        <% end %>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :timeseries}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)}>
      <div class={Theme.slot(:widget, :title_row)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>Timeseries</p>
          <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
        </div>
      </div>
      <div :if={is_list(@widget.value) && @widget.value != []} class={Theme.slot(:widget, :chart)}>
        <div :for={point <- @widget.value} class={Theme.slot(:widget, :bar)} style={"height: #{bar_height(point, @widget.value)}%;"}></div>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :chart}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)}>
      <div class={Theme.slot(:widget, :title_row)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>{@widget.chart.type || "Chart"}</p>
          <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
        </div>
        <span :if={@widget.chart.dataset} class={Theme.slot(:badge, :base)}>{short_chart_dataset(@widget.chart.dataset)}</span>
      </div>
      <div class={Theme.slot(:widget, :chart)}>
        <div class={Theme.slot(:widget, :chart_placeholder)}>
          <div class={Theme.slot(:widget, :chart_line)}></div>
          <div class={Theme.slot(:widget, :chart_axis)}>
            <span>{chart_axis_label(@widget.chart.x)}</span>
            <span>{chart_axis_label(@widget.chart.y)}</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :table}} = assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :framed)} style={widget_style(@widget)}>
      <div class={Theme.slot(:widget, :header)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>Table</p>
          <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
        </div>
      </div>
      <table :if={table_rows(@widget.value) != []} class={Theme.slot(:table, :root)}>
        <thead class={Theme.slot(:table, :head)}>
          <tr><th :for={column <- table_columns(@widget)} class={table_header_class(column)}>{table_column_label(column)}</th></tr>
        </thead>
        <tbody class={Theme.slot(:table, :body)}>
          <tr :for={row <- table_rows(@widget.value)} class={Theme.slot(:table, :row)}><td :for={column <- table_columns(@widget)} class={table_data_class(column)}>{table_cell_display(column, table_cell(row, column))}</td></tr>
        </tbody>
      </table>
    </div>
    """
  end

  def widget(assigns) do
    ~H"""
    <div class={Theme.slot(:widget, :root)} style={widget_style(@widget)}>
      <p class={Theme.slot(:widget, :eyebrow)}>{@widget.type}</p>
      <h3 class={Theme.slot(:widget, :title)}>{@widget.title}</h3>
    </div>
    """
  end
end
