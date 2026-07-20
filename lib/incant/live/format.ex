defmodule Incant.Live.Format do
  @moduledoc false

  @formats ~w(money currency number compact_number datetime date time boolean relative percent id)a

  def value(value, format) do
    do_value(value, format_name(format))
  rescue
    _error in [ArgumentError, ArithmeticError, FunctionClauseError, Protocol.UndefinedError] ->
      fallback(value)
  end

  defp do_value(nil, _format), do: ""
  defp do_value(value, :money), do: currency(value)
  defp do_value(value, :currency), do: currency(value)
  defp do_value(value, :number), do: number(value)
  defp do_value(value, :compact_number), do: compact_number(value)
  defp do_value(value, :datetime), do: datetime(value)
  defp do_value(value, :date), do: date(value)
  defp do_value(value, :time), do: time(value)
  defp do_value(true, :boolean), do: "Yes"
  defp do_value(false, :boolean), do: "No"
  defp do_value(value, :relative), do: relative(value)
  defp do_value(value, :id), do: identifier(value)
  defp do_value(value, :percent) when is_number(value), do: "#{Float.round(value * 100, 2)}%"
  defp do_value(value, _format), do: fallback(value)

  defp format_name(format) when format in @formats, do: format

  defp format_name(format) when is_binary(format) do
    format = String.to_existing_atom(format)
    if format in @formats, do: format
  rescue
    ArgumentError -> nil
  end

  defp format_name(_format), do: nil

  defp currency(%Decimal{} = value), do: value |> Decimal.to_float() |> currency()
  defp currency(value) when is_integer(value), do: "$#{delimit_integer(value)}"

  defp currency(value) when is_float(value) do
    [integer, fraction] = value |> :erlang.float_to_binary(decimals: 2) |> String.split(".")
    "$#{delimit_integer(integer)}.#{fraction}"
  end

  defp currency(value), do: fallback(value)

  defp number(%Decimal{} = value),
    do: value |> Decimal.to_string(:normal) |> delimit_number_string()

  defp number(value) when is_integer(value), do: delimit_integer(value)

  defp number(value) when is_float(value) do
    value
    |> :erlang.float_to_binary([:compact, decimals: 6])
    |> delimit_number_string()
  end

  defp number(value), do: fallback(value)

  defp compact_number(%Decimal{} = value),
    do: value |> Decimal.to_float() |> compact_number()

  defp compact_number(value) when is_integer(value) and abs(value) < 1_000,
    do: delimit_integer(value)

  defp compact_number(value) when is_number(value) do
    abs_value = abs(value)

    cond do
      abs_value >= 1_000_000_000 -> compact_scaled(value, 1_000_000_000, "B")
      abs_value >= 1_000_000 -> compact_scaled(value, 1_000_000, "M")
      abs_value >= 10_000 -> compact_scaled(value, 1_000, "k")
      true -> number(value)
    end
  end

  defp compact_number(value), do: fallback(value)

  defp compact_scaled(value, scale, suffix) do
    scaled =
      (value / scale)
      |> Float.round(1)
      |> :erlang.float_to_binary(decimals: 1)
      |> String.trim_trailing(".0")

    "#{scaled}#{suffix}"
  end

  defp datetime(%DateTime{} = value), do: Calendar.strftime(value, "%Y-%m-%d %H:%M")
  defp datetime(%NaiveDateTime{} = value), do: Calendar.strftime(value, "%Y-%m-%d %H:%M")

  defp datetime(value) when is_binary(value),
    do: value |> parse_datetime() |> datetime_or_fallback(value)

  defp datetime(value), do: fallback(value)

  defp date(%Date{} = value), do: Date.to_iso8601(value)
  defp date(%DateTime{} = value), do: value |> DateTime.to_date() |> Date.to_iso8601()
  defp date(%NaiveDateTime{} = value), do: value |> NaiveDateTime.to_date() |> Date.to_iso8601()
  defp date(value) when is_binary(value), do: value |> parse_date() |> date_or_fallback(value)
  defp date(value), do: fallback(value)

  defp time(%Time{} = value), do: value |> Time.truncate(:second) |> Time.to_iso8601()
  defp time(%DateTime{} = value), do: value |> DateTime.to_time() |> time()
  defp time(%NaiveDateTime{} = value), do: value |> NaiveDateTime.to_time() |> time()
  defp time(value) when is_binary(value), do: value |> parse_time() |> time_or_fallback(value)
  defp time(value), do: fallback(value)

  defp relative(%DateTime{} = value),
    do: relative_seconds(DateTime.diff(DateTime.utc_now(), value, :second))

  defp relative(%NaiveDateTime{} = value) do
    now = DateTime.utc_now() |> DateTime.to_naive()
    relative_seconds(NaiveDateTime.diff(now, value, :second))
  end

  defp relative(value) when is_binary(value),
    do: value |> parse_datetime() |> relative_or_fallback(value)

  defp relative(value), do: fallback(value)

  defp identifier(value) when is_binary(value) and byte_size(value) > 8,
    do: String.slice(value, 0, 8) <> "…"

  defp identifier(value), do: fallback(value)

  defp relative_seconds(seconds) when seconds < 0, do: "in #{relative_unit(abs(seconds))}"
  defp relative_seconds(seconds), do: "#{relative_unit(seconds)} ago"

  defp relative_unit(seconds) when seconds < 60, do: "#{seconds}s"
  defp relative_unit(seconds) when seconds < 3_600, do: "#{div(seconds, 60)}m"
  defp relative_unit(seconds) when seconds < 86_400, do: "#{div(seconds, 3_600)}h"
  defp relative_unit(seconds), do: "#{div(seconds, 86_400)}d"

  defp parse_datetime(value) do
    with {:error, _reason} <- DateTime.from_iso8601(value),
         {:error, _reason} <- NaiveDateTime.from_iso8601(value) do
      :error
    else
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:ok, naive_datetime} -> {:ok, naive_datetime}
    end
  end

  defp parse_date(value) do
    with {:error, _reason} <- Date.from_iso8601(value),
         :error <- parse_datetime(value) do
      :error
    else
      {:ok, %Date{} = date} -> {:ok, date}
      {:ok, datetime} -> {:ok, datetime}
    end
  end

  defp parse_time(value) do
    with {:error, _reason} <- Time.from_iso8601(value),
         :error <- parse_datetime(value) do
      :error
    else
      {:ok, %Time{} = time} -> {:ok, time}
      {:ok, datetime} -> {:ok, datetime}
    end
  end

  defp datetime_or_fallback({:ok, value}, _fallback), do: datetime(value)
  defp datetime_or_fallback(:error, value), do: fallback(value)

  defp date_or_fallback({:ok, value}, _fallback), do: date(value)
  defp date_or_fallback(:error, value), do: fallback(value)

  defp time_or_fallback({:ok, value}, _fallback), do: time(value)
  defp time_or_fallback(:error, value), do: fallback(value)

  defp relative_or_fallback({:ok, value}, _fallback), do: relative(value)
  defp relative_or_fallback(:error, value), do: fallback(value)

  defp delimit_number_string("-" <> rest),
    do: IO.iodata_to_binary(["-", delimit_number_string(rest)])

  defp delimit_number_string(value) when is_binary(value) do
    case String.split(value, ".", parts: 2) do
      [integer] -> delimit_integer(integer)
      [integer, fraction] -> "#{delimit_integer(integer)}.#{fraction}"
    end
  end

  defp delimit_integer(value) when is_integer(value),
    do: value |> Integer.to_string() |> delimit_integer()

  defp delimit_integer("-" <> rest), do: IO.iodata_to_binary(["-", delimit_integer(rest)])

  defp delimit_integer(value) when is_binary(value) do
    value
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.map_join(",", &Enum.join/1)
  end

  defp fallback(value) do
    to_string(value)
  rescue
    Protocol.UndefinedError -> inspect(value)
  end
end
