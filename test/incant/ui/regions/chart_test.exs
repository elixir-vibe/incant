defmodule Incant.UI.Regions.ChartTest do
  use ExUnit.Case, async: true

  alias Incant.UI.Regions.Chart

  test "normalizes external chart maps into typed points" do
    assert [
             %Chart.Point{label: "10:00", value: 2},
             %Chart.Point{label: "11:00", value: 0}
           ] =
             Chart.normalize_points(%{
               "points" => [
                 %{"timestamp" => "10:00", "value" => 2},
                 %{x: "11:00", y: 0}
               ]
             })
  end

  test "drops invalid external points" do
    assert Chart.normalize_points([%{"value" => "invalid"}, :invalid]) == []
  end
end
