defmodule Incant.UI.Regions.WidgetGrid do
  @moduledoc """
  Dashboard widget grid model.
  """

  defstruct widgets: [], columns: 12, row_height: 8

  defmodule Widget do
    @moduledoc false
    defstruct [
      :id,
      :type,
      :title,
      :value,
      :display,
      :delta,
      :span,
      :chart,
      :error,
      :loading,
      :source
    ]
  end

  def from_context(context) do
    widgets = Enum.map(context.dashboard.widgets, &widget_from_metadata(&1, context))
    grid = context.dashboard.grid || []

    %__MODULE__{
      widgets: widgets,
      columns: option(grid, :columns, 12),
      row_height: option(grid, :row_height, 8)
    }
  end

  defp widget_from_metadata(widget, context) do
    value = Map.get(context.widget_values, widget.id)
    error = if match?({:error, _message}, value), do: elem(value, 1)

    %Widget{
      id: widget.id,
      type: widget.type,
      title: option(widget.opts, :label) || humanize(widget.id),
      value: value,
      display: display_value(value, widget),
      delta: stat_delta(value, widget),
      span: option(widget.opts, :span),
      chart: chart_from_metadata(widget, value),
      error: error,
      loading: not Map.has_key?(context.widget_values, widget.id),
      source: widget
    }
  end

  defp chart_from_metadata(%{type: :chart} = widget, value) do
    %Incant.UI.Regions.Chart{
      id: widget.id,
      type: option(widget.opts, :chart_type),
      dataset: option(widget.opts, :dataset),
      x: option(widget.opts, :x),
      y: option(widget.opts, :y),
      series: option(widget.opts, :series),
      drilldown: option(widget.opts, :drilldown),
      title: option(widget.opts, :label) || humanize(widget.id),
      value: value,
      opts: widget.opts
    }
  end

  defp chart_from_metadata(_widget, _value), do: nil

  defp display_value({:error, _message}, _widget), do: nil

  defp display_value(value, %{type: :stat} = widget) do
    value
    |> stat_value()
    |> Incant.Live.Format.value(option(widget.opts, :format, :number))
  end

  defp display_value(value, _widget) when is_list(value) or is_map(value), do: value

  defp display_value(value, widget),
    do: Incant.Live.Format.value(value, option(widget.opts, :format))

  defp stat_delta(value, %{type: :stat}) when is_map(value), do: option(value, :delta)
  defp stat_delta(_value, _widget), do: nil

  defp stat_value(value) when is_map(value), do: option(value, :value)
  defp stat_value(value), do: value

  defp option(options, key, default \\ nil)
  defp option(options, key, default) when is_map(options), do: Map.get(options, key, default)
  defp option(options, key, default) when is_list(options), do: Keyword.get(options, key, default)
  defp option(_options, _key, default), do: default

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
