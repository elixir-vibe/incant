defmodule Incant.UI.Adapters.LiveView.Helpers do
  @moduledoc false

  import Incant.Live.Routes

  alias Incant.Live.Authorization
  alias Incant.UI.Adapters.LiveView.Theme

  def selected_values(nil), do: []
  def selected_values(values) when is_list(values), do: Enum.map(values, &to_string/1)
  def selected_values(value), do: [to_string(value)]

  def map_value(value, key) when is_map(value), do: value |> Map.get(key, "") |> input_value()
  def map_value(_value, _key), do: ""

  def input_value(%Date{} = date), do: Date.to_iso8601(date)
  def input_value(value), do: value

  def detail_link?(context, column, row, row_id) do
    column.opts[:link] && row_detail_link?(context, row, row_id)
  end

  def row_detail_link?(context, row, row_id) do
    row_id &&
      Authorization.allowed?(
        context.admin,
        :view_row,
        context.actor,
        authorization_context(context, row)
      )
  end

  def action_allowed?(context, %{name: :edit}, row) do
    if form_enabled?(context.resource) do
      Authorization.allowed?(
        context.admin,
        :edit,
        context.actor,
        authorization_context(context, row)
      )
    else
      Authorization.allowed?(
        context.admin,
        :run_action,
        context.actor,
        authorization_context(context, row, %{action: :edit})
      )
    end
  end

  def action_allowed?(context, action, row) do
    Authorization.allowed?(
      context.admin,
      :run_action,
      context.actor,
      authorization_context(context, row, %{action: action.name})
    )
  end

  def authorization_context(context, row, extra \\ %{}) do
    context |> Map.from_struct() |> Map.merge(%{row: row}) |> Map.merge(extra)
  end

  def form_enabled?(resource), do: not is_nil(resource.repo) and not is_nil(resource.changeset)
  def action_label(action), do: action.opts[:label] || humanize(action.name)

  def confirm_message(%{opts: opts}) do
    case opts[:confirm] do
      true -> "Are you sure?"
      message when is_binary(message) -> message
      _other -> nil
    end
  end

  def cell_class(cell) do
    [
      Theme.slot(:table, :cell, align: cell_align(cell), truncate: truncate_cell?(cell)),
      responsive_column_class(cell_priority(cell))
    ]
  end

  def table_header_class(column) do
    [
      Theme.slot(:table, :header_cell, align: table_column_align(column)),
      responsive_column_class(column_priority(column))
    ]
  end

  def table_sort_button_class(column) do
    Theme.slot(:table, :sort_button, align: table_column_align(column))
  end

  def table_data_class(column) do
    [
      Theme.slot(:table, :cell, align: table_column_align(column)),
      responsive_column_class(column_priority(column))
    ]
  end

  def table_column_align(column), do: column_align(column)

  def cell_content_class(cell) do
    Theme.slot(
      :table,
      :cell_content,
      truncate: truncate_cell?(cell),
      identifier: id_cell?(cell)
    )
  end

  def cell_title(cell) do
    cond do
      cell_sensitive?(cell) -> redacted_cell_display()
      id_cell?(cell) -> string_value(cell.value)
      truncate_cell?(cell) && is_binary(cell.display) -> String.slice(cell.display, 0, 200)
      true -> nil
    end
  end

  def cell_sensitive?(cell), do: Incant.Sensitive.sensitive?(cell_opts(cell))
  def id_cell?(cell), do: format?(cell.format, :id)
  def boolean_cell?(cell), do: format?(cell.format, :boolean)
  def boolean_value?(cell), do: cell.value in [true, "true", 1]

  def redacted_cell_display, do: "•••• redacted"

  defp truncate_cell?(cell) do
    string_length(cell.display) > 120 || cell_sensitive?(cell) ||
      opt(cell_opts(cell), :format) == :text || cell.format == :text
  end

  defp cell_priority(cell), do: cell |> cell_opts() |> opt(:priority)

  defp column_priority(%{priority: priority}), do: priority
  defp column_priority(%{opts: opts}), do: opt(opts, :priority)
  defp column_priority(_column), do: nil

  defp responsive_column_class(priority) when priority in [:secondary, "secondary", 2],
    do: "hidden sm:table-cell"

  defp responsive_column_class(priority) when priority in [:tertiary, "tertiary", 3],
    do: "hidden lg:table-cell"

  defp responsive_column_class(_priority), do: nil

  defp cell_opts(%{source: %{opts: opts}}) when is_list(opts) or is_map(opts), do: opts
  defp cell_opts(_cell), do: []

  defp opt(opts, key) when is_list(opts), do: Keyword.get(opts, key)
  defp opt(opts, key) when is_map(opts), do: Map.get(opts, key) || Map.get(opts, to_string(key))

  defp cell_align(cell),
    do: align(cell.source.opts[:align], cell.source.opts[:format] || cell.format)

  defp column_align(%Incant.Dashboard.Column{opts: opts}), do: align(opts[:align], opts[:format])
  defp column_align(%{align: align, format: format}), do: align(align, format)
  defp column_align(_column), do: :left

  defp align(align, _format) when align in [:right, "right"], do: :right
  defp align(align, _format) when align in [:left, "left"], do: :left
  defp align(_align, format), do: if(numeric_format?(format), do: :right, else: :left)

  defp numeric_format?(format) when format in [:number, :money, :currency, :percent], do: true

  defp numeric_format?(format) when is_binary(format) do
    format |> String.to_existing_atom() |> numeric_format?()
  rescue
    ArgumentError -> false
  end

  defp numeric_format?(_format), do: false

  defp format?(format, target) when is_atom(format), do: format == target
  defp format?(format, target) when is_binary(format), do: format == to_string(target)
  defp format?(_format, _target), do: false

  defp string_value(value) when is_binary(value), do: value
  defp string_value(value), do: to_string(value)

  defp string_length(value) when is_binary(value), do: String.length(value)
  defp string_length(_value), do: 0

  def sort_column("-" <> column), do: column
  def sort_column(column), do: column
  def sort_direction("-" <> _column), do: "↓"
  def sort_direction(_column), do: "↑"

  def form_source(nil), do: %{}
  def form_source(%{__struct__: Ecto.Changeset, params: params}) when is_map(params), do: params

  def form_source(%{__struct__: Ecto.Changeset, changes: changes}) when is_map(changes),
    do: changes

  def form_source(changeset), do: changeset

  def form_eyebrow(:new), do: "New record"
  def form_eyebrow(:edit), do: "Edit record"

  def form_title(resource, record, :edit), do: Incant.Live.Rows.title(record, resource)
  def form_title(resource, _record, :new), do: "New #{short_module(resource.module)}"

  def form_back_path(env) do
    case {env.context.form_mode, Incant.Live.Rows.id(env.context.form_record)} do
      {:edit, nil} -> resource_path(env.base_path, env.context.resource)
      {:edit, id} -> resource_detail_path(env.base_path, env.context.resource, id)
      {:new, _id} -> resource_path(env.base_path, env.context.resource)
    end
  end

  def form_input_type(%{source: %{type: type}}) when type in [:number, :date, :time],
    do: to_string(type)

  def form_input_type(%{source: %{type: :datetime}}), do: "datetime-local"
  def form_input_type(_field), do: "text"

  def form_input_value(%{source: %{type: :datetime}, value: %DateTime{} = value}) do
    value |> DateTime.to_naive() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()
  end

  def form_input_value(%{source: %{type: :datetime}, value: %NaiveDateTime{} = value}) do
    value |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()
  end

  def form_input_value(%{source: %{type: :time}, value: %Time{} = value}),
    do: value |> Time.truncate(:second) |> Time.to_iso8601()

  def form_input_value(%{value: nil}), do: nil
  def form_input_value(%{value: %Decimal{} = value}), do: Decimal.to_string(value)
  def form_input_value(%{value: value}), do: value

  def widget_style(widget) do
    case widget.span do
      nil -> nil
      span -> "--incant-widget-span: #{span};"
    end
  end

  def chart_axis_label(nil), do: "—"
  def chart_axis_label({field, _opts}), do: to_string(field)
  def chart_axis_label(field), do: to_string(field)

  def short_chart_dataset(nil), do: nil
  def short_chart_dataset(module) when is_atom(module), do: short_module(module)
  def short_chart_dataset(dataset), do: to_string(dataset)

  def bar_height(point, points) do
    value = numeric_value(point)
    max_value = points |> Enum.map(&numeric_value/1) |> Enum.max(fn -> 1 end)

    if max_value > 0, do: max(round(value / max_value * 100), 4), else: 4
  end

  def chart_points(points) when is_list(points),
    do: Enum.filter(points, &match?(%Incant.UI.Regions.Chart.Point{}, &1))

  def chart_points(_points), do: []

  def chart_polyline(points) do
    points
    |> chart_coordinates()
    |> Enum.map_join(" ", fn %{x: x, y: y} -> "#{coordinate(x)},#{coordinate(y)}" end)
  end

  def chart_area(points) do
    coordinates = chart_coordinates(points)

    case coordinates do
      [] ->
        ""

      [point] ->
        "0,40 #{coordinate(point.x)},#{coordinate(point.y)} 100,40"

      [first | _] ->
        last = List.last(coordinates)
        "#{coordinate(first.x)},40 #{chart_polyline(points)} #{coordinate(last.x)},40"
    end
  end

  def chart_bars(points) do
    points = chart_points(points)
    count = max(length(points), 1)
    gap = 1
    width = max((100 - gap * (count - 1)) / count, 1)
    max_value = points |> Enum.map(&numeric_value/1) |> Enum.max(fn -> 1 end)

    points
    |> Enum.with_index()
    |> Enum.map(fn {point, index} ->
      height = if max_value > 0, do: max(numeric_value(point) / max_value * 40, 2), else: 2

      %{
        x: index * (width + gap),
        y: 40 - height,
        width: width,
        height: height,
        label: chart_point_label(point)
      }
    end)
  end

  def chart_min(points),
    do: points |> chart_points() |> Enum.map(&numeric_value/1) |> Enum.min(fn -> 0 end)

  def chart_max(points),
    do: points |> chart_points() |> Enum.map(&numeric_value/1) |> Enum.max(fn -> 0 end)

  def chart_first_label(points),
    do: points |> chart_points() |> List.first() |> chart_point_label()

  def chart_last_label(points), do: points |> chart_points() |> List.last() |> chart_point_label()

  def chart_point_label(nil), do: "—"

  def chart_point_label(%Incant.UI.Regions.Chart.Point{label: label, value: value}) do
    if is_nil(label), do: Incant.Live.Format.value(value, :number), else: to_string(label)
  end

  def numeric_value(%Incant.UI.Regions.Chart.Point{value: value}), do: value
  def numeric_value(_value), do: 0

  defp chart_coordinates(points) do
    points = chart_points(points)
    count = length(points)
    min_value = chart_min(points)
    max_value = chart_max(points)
    range = max(max_value - min_value, 1)

    points
    |> Enum.with_index()
    |> Enum.map(fn {point, index} ->
      x = if count <= 1, do: 50, else: index / (count - 1) * 100
      y = 40 - (numeric_value(point) - min_value) / range * 40
      %{x: x, y: y}
    end)
  end

  defp coordinate(value),
    do: value |> Kernel.*(1.0) |> Float.round(2) |> :erlang.float_to_binary(decimals: 2)

  def table_columns(%Incant.UI.Regions.WidgetGrid.Widget{source: %{opts: opts}, value: value}) do
    case Keyword.get(opts, :columns) do
      columns when is_list(columns) and columns != [] -> columns
      _other -> table_columns(value)
    end
  end

  def table_columns(%Incant.UI.Regions.WidgetGrid.Widget{value: value}), do: table_columns(value)

  def table_columns(%{columns: columns}) when is_list(columns), do: columns
  def table_columns(%{"columns" => columns}) when is_list(columns), do: columns

  def table_columns([row | _]) when is_map(row),
    do: row |> Map.keys() |> Enum.map(&to_string/1) |> Enum.sort()

  def table_columns(_rows), do: []

  def table_rows(%{rows: rows}) when is_list(rows), do: rows
  def table_rows(%{"rows" => rows}) when is_list(rows), do: rows
  def table_rows(rows) when is_list(rows), do: rows
  def table_rows(_rows), do: []

  def table_cell(row, column) when is_map(row) do
    column = table_column_name(column)

    case Map.fetch(row, column) do
      {:ok, value} -> value
      :error -> row |> Map.fetch(existing_atom(column)) |> elem_or_nil()
    end
  end

  def table_cell(_row, _column), do: nil

  def table_column_name(%Incant.Dashboard.Column{name: name}), do: to_string(name)
  def table_column_name(%{name: name}), do: to_string(name)
  def table_column_name(%{id: id}), do: to_string(id)
  def table_column_name(column), do: to_string(column)

  def table_column_label(%Incant.Dashboard.Column{name: name, opts: opts}),
    do: Keyword.get(opts, :label) || humanize(name)

  def table_column_label(%{label: label}) when is_binary(label), do: label
  def table_column_label(column), do: column |> table_column_name() |> humanize()

  def table_cell_display(%Incant.Dashboard.Column{opts: opts}, value),
    do: Incant.Live.Format.value(value, Keyword.get(opts, :format))

  def table_cell_display(%{format: format}, value), do: Incant.Live.Format.value(value, format)
  def table_cell_display(_column, value), do: Incant.Live.Format.value(value, nil)

  defp elem_or_nil({:ok, value}), do: value
  defp elem_or_nil(:error), do: nil

  defp existing_atom(column) do
    String.to_existing_atom(column)
  rescue
    ArgumentError -> nil
  end

  def authorization_message({:unauthorized, action}), do: "Not authorized to #{action}."
  def authorization_message(reason) when is_atom(reason), do: "Not authorized: #{reason}."
  def authorization_message(reason), do: "Not authorized: #{inspect(reason)}."

  def short_module(nil), do: "Admin"
  def short_module(module), do: module |> Module.split() |> List.last()

  def humanize(value), do: Incant.Naming.label(value)
end
