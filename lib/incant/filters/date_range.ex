defmodule Incant.Filters.DateRange do
  @moduledoc """
  Date range filter implementation.
  """

  @behaviour Incant.Filter

  use Phoenix.Component

  import Incant.Live.Components

  alias Incant.Filters.Shared

  @impl true
  def control(filter, value, _assigns) do
    assigns = %{filter: filter, value: value || %{}}

    ~H"""
    <div class="grid grid-cols-2 gap-2">
      <.input
        type="date"
        name={"table[filters][#{@filter.name}][from]"}
        value={filter_value(@value, "from")}
        placeholder={"#{@filter.name} from"}
      />
      <.input
        type="date"
        name={"table[filters][#{@filter.name}][to]"}
        value={filter_value(@value, "to")}
        placeholder={"#{@filter.name} to"}
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
    Shared.apply_query_callback(filter, queryable, value, context)
  end

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
