defmodule Incant.UI.Regions.Chart do
  @moduledoc """
  Semantic chart specification for dashboard widgets.
  """

  defmodule Point do
    @moduledoc false

    @enforce_keys [:value]
    defstruct [:label, :value]
  end

  defstruct [
    :id,
    :type,
    :dataset,
    :x,
    :y,
    :series,
    :drilldown,
    :title,
    value: [],
    opts: []
  ]

  @doc false
  def normalize_points(%{points: points}) when is_list(points), do: normalize_points(points)
  def normalize_points(%{"points" => points}) when is_list(points), do: normalize_points(points)

  def normalize_points(points) when is_list(points) do
    points
    |> Enum.map(&normalize_point/1)
    |> Enum.reject(&is_nil/1)
  end

  def normalize_points(_points), do: []

  defp normalize_point(%Point{} = point), do: point
  defp normalize_point(value) when is_number(value), do: %Point{value: value}

  defp normalize_point(point) when is_map(point) do
    value = external_value(point, :value) || external_value(point, :y)

    if is_number(value) do
      %Point{
        label:
          external_value(point, :label) || external_value(point, :x) ||
            external_value(point, :timestamp),
        value: value
      }
    end
  end

  defp normalize_point(_point), do: nil

  defp external_value(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> value
      :error -> Map.get(map, to_string(key))
    end
  end
end
