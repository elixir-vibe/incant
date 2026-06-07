defmodule Incant.Params do
  @moduledoc false

  def positive_integer(value, _default) when is_integer(value) and value > 0, do: value

  def positive_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {integer, ""} when integer > 0 -> integer
      _other -> default
    end
  end

  def positive_integer(_value, default), do: default
end
