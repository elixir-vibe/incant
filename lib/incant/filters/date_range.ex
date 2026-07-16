defmodule Incant.Filters.DateRange do
  @moduledoc """
  Date range filter implementation.
  """

  @behaviour Incant.Filter

  use Phoenix.Component

  import Ecto.Query
  import Incant.Live.Components

  alias Incant.Filters.Shared

  @impl true
  def control(filter, value, _assigns) do
    assigns = %{filter: filter, value: value || %{}}

    ~H"""
    <div class="grid grid-cols-2 gap-2">
      <.input
        type="text"
        name={"table[filters][#{@filter.name}][from]"}
        value={filter_value(@value, "from")}
        placeholder="From"
        class="font-mono"
      />
      <.input
        type="text"
        name={"table[filters][#{@filter.name}][to]"}
        value={filter_value(@value, "to")}
        placeholder="To"
        class="font-mono"
      />
    </div>
    """
  end

  @impl true
  def match?(_filter, _row, value) when value in [nil, %{}], do: true

  def match?(filter, row, value) when is_map(value) do
    row_date = row |> Shared.row_value(filter.name) |> date_value()
    from_date = value |> Map.get("from") |> date_value()
    to_date = value |> Map.get("to") |> date_value()

    (is_nil(from_date) or Date.compare(row_date, from_date) != :lt) and
      (is_nil(to_date) or Date.compare(row_date, to_date) != :gt)
  rescue
    _error in [ArgumentError, FunctionClauseError] -> true
  end

  def match?(_filter, _row, _value), do: true

  @impl true
  def apply_query(filter, queryable, value, context) do
    if Shared.custom_query?(filter) or Shared.blank?(value) do
      Shared.apply_query_callback(filter, queryable, value, context)
    else
      queryable
      |> apply_from(filter, date_value(Map.get(value, "from")), context)
      |> apply_to(filter, date_value(Map.get(value, "to")), context)
    end
  rescue
    _error in [ArgumentError, Ecto.QueryError] -> queryable
  end

  defp apply_from(queryable, _filter, nil, _context), do: queryable

  defp apply_from(queryable, filter, from, context) do
    from = day_start(from, field_type(filter, context))
    where(queryable, [row], field(row, ^filter.name) >= ^from)
  end

  defp apply_to(queryable, _filter, nil, _context), do: queryable

  defp apply_to(queryable, filter, to, context) do
    case field_type(filter, context) do
      type when type in [:utc_datetime, :utc_datetime_usec] ->
        boundary = DateTime.new!(Date.add(to, 1), ~T[00:00:00], "Etc/UTC")
        where(queryable, [row], field(row, ^filter.name) < ^boundary)

      type when type in [:naive_datetime, :naive_datetime_usec] ->
        boundary = NaiveDateTime.new!(Date.add(to, 1), ~T[00:00:00])
        where(queryable, [row], field(row, ^filter.name) < ^boundary)

      _type ->
        where(queryable, [row], field(row, ^filter.name) <= ^to)
    end
  end

  defp day_start(date, type) when type in [:utc_datetime, :utc_datetime_usec],
    do: DateTime.new!(date, ~T[00:00:00], "Etc/UTC")

  defp day_start(date, type) when type in [:naive_datetime, :naive_datetime_usec],
    do: NaiveDateTime.new!(date, ~T[00:00:00])

  defp day_start(date, _type), do: date

  defp field_type(filter, %{resource: %{schema: schema}}) when is_atom(schema) do
    if function_exported?(schema, :__schema__, 2),
      do: apply(schema, :__schema__, [:type, filter.name])
  end

  defp field_type(_filter, _context), do: nil

  defp filter_value(value, key) when is_map(value), do: Map.get(value, key, "")
  defp filter_value(_value, _key), do: ""

  defp date_value(nil), do: nil
  defp date_value(""), do: nil
  defp date_value(%Date{} = date), do: date
  defp date_value(%DateTime{} = date_time), do: DateTime.to_date(date_time)
  defp date_value(%NaiveDateTime{} = date_time), do: NaiveDateTime.to_date(date_time)

  defp date_value(value) do
    value
    |> to_string()
    |> String.slice(0, 10)
    |> Date.from_iso8601!()
  end
end
