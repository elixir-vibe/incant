defmodule Incant.UI.Regions.WidgetGrid do
  @moduledoc """
  Dashboard widget grid model.
  """

  defstruct widgets: [], columns: 12, row_height: 8

  defmodule Widget do
    @moduledoc false
    defstruct [:id, :type, :title, :value, :display, :span, :error, :loading, :source]
  end

  def from_context(context) do
    widgets = Enum.map(context.dashboard.widgets, &widget_from_metadata(&1, context))
    grid = context.dashboard.grid || []

    %__MODULE__{
      widgets: widgets,
      columns: Keyword.get(grid, :columns, 12),
      row_height: Keyword.get(grid, :row_height, 8)
    }
  end

  defp widget_from_metadata(widget, context) do
    value = Map.get(context.widget_values, widget.id)
    error = if match?({:error, _message}, value), do: elem(value, 1)

    %Widget{
      id: widget.id,
      type: widget.type,
      title: widget.opts[:label] || humanize(widget.id),
      value: value,
      display: display_value(value, widget),
      span: widget.opts[:span],
      error: error,
      loading: not Map.has_key?(context.widget_values, widget.id),
      source: widget
    }
  end

  defp display_value({:error, _message}, _widget), do: nil
  defp display_value(value, _widget) when is_list(value) or is_map(value), do: value
  defp display_value(value, widget), do: Incant.Live.Format.value(value, widget.opts[:format])

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
