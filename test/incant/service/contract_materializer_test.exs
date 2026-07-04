defmodule Incant.Service.ContractMaterializerTest do
  use ExUnit.Case, async: true

  alias Incant.Service.ContractMaterializer

  test "materializes transport-shaped dashboard widget columns at the service boundary" do
    surface = %{
      id: "operations",
      kind: :dashboard,
      title: "Operations",
      widgets: [
        %{
          "id" => "recent_usage",
          "type" => :table,
          "opts" => %{
            "label" => "Recent usage",
            "columns" => [
              %{"name" => :timestamp, "opts" => %{"label" => "Timestamp", "format" => :datetime}},
              %{"name" => :cost, "opts" => %{"label" => "Cost", "format" => :money}}
            ]
          }
        }
      ]
    }

    assert %{widgets: [widget]} = ContractMaterializer.surface(surface)

    assert %Incant.Dashboard.Widget{id: "recent_usage", type: :table, opts: opts} = widget
    assert Keyword.fetch!(opts, :label) == "Recent usage"

    assert [timestamp, cost] = Keyword.fetch!(opts, :columns)
    assert %Incant.Table.Column{name: :timestamp, opts: timestamp_opts} = timestamp
    assert Keyword.fetch!(timestamp_opts, :label) == "Timestamp"
    assert Keyword.fetch!(timestamp_opts, :format) == :datetime
    assert %Incant.Table.Column{name: :cost, opts: cost_opts} = cost
    assert Keyword.fetch!(cost_opts, :label) == "Cost"
    assert Keyword.fetch!(cost_opts, :format) == :money
  end

  test "leaves non-dashboard surfaces unchanged" do
    surface = %{id: "user", kind: :resource, table: %{columns: []}}

    assert ContractMaterializer.surface(surface) == surface
  end
end
