defmodule Incant.UI.Adapters.LiveView.Helpers do
  @moduledoc false

  import Incant.Live.Routes

  alias Incant.Live.Authorization
  alias Incant.UI.Adapters.LiveView.Theme

  def input_class do
    "h-8 rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] transition focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]"
  end

  def selected_values(nil), do: []
  def selected_values(values) when is_list(values), do: Enum.map(values, &to_string/1)
  def selected_values(value), do: [to_string(value)]

  def map_value(value, key) when is_map(value), do: value |> Map.get(key, "") |> input_value()
  def map_value(_value, _key), do: ""

  def input_value(%Date{} = date), do: Date.to_iso8601(date)
  def input_value(value), do: value

  def detail_link?(context, column, row, row_id) do
    column.opts[:link] && row_id &&
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

  def action_class(action) do
    [
      "rounded-md px-1.5 py-1 text-xs transition",
      action.opts[:tone] == :danger &&
        "text-[var(--incant-text-muted)] hover:bg-[color-mix(in_oklab,var(--incant-error)_8%,transparent)] hover:text-[var(--incant-error)]",
      action.opts[:tone] != :danger &&
        "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
    ]
  end

  def cell_class(cell) do
    align = if cell.source.opts[:align] == :right, do: :right, else: :left
    Theme.slot(:table, :cell, align: align)
  end

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
      span -> "grid-column: span #{span} / span #{span};"
    end
  end

  def bar_height(point, points) do
    value = numeric_value(point)
    max_value = points |> Enum.map(&numeric_value/1) |> Enum.max(fn -> 1 end)

    if max_value > 0, do: max(round(value / max_value * 100), 4), else: 4
  end

  def numeric_value(%{value: value}) when is_number(value), do: value
  def numeric_value(%{"value" => value}) when is_number(value), do: value
  def numeric_value(%{y: value}) when is_number(value), do: value
  def numeric_value(%{"y" => value}) when is_number(value), do: value
  def numeric_value(value) when is_number(value), do: value
  def numeric_value(_value), do: 0

  def table_columns([row | _]) when is_map(row), do: Map.keys(row)
  def table_columns(_rows), do: []

  def authorization_message({:unauthorized, action}), do: "Not authorized to #{action}."
  def authorization_message(reason) when is_atom(reason), do: "Not authorized: #{reason}."
  def authorization_message(reason), do: "Not authorized: #{inspect(reason)}."

  def short_module(nil), do: "Admin"
  def short_module(module), do: module |> Module.split() |> List.last()

  def humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
