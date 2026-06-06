defmodule Incant.Live.Format do
  @moduledoc false

  def value(value, :money), do: currency(value)
  def value(value, :currency), do: currency(value)
  def value(value, :percent) when is_number(value), do: "#{Float.round(value * 100, 2)}%"
  def value(value, :relative), do: to_string(value)
  def value(value, _format), do: to_string(value)

  defp currency(value) when is_integer(value), do: "$#{value}"

  defp currency(value) when is_float(value),
    do: "$#{:erlang.float_to_binary(value, decimals: 2)}"

  defp currency(value), do: to_string(value)
end
