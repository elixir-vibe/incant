defmodule Incant.DashboardTest do
  use ExUnit.Case, async: true

  defmodule Metrics do
    def total_requests(_params, _context), do: 42
  end

  defmodule CampaignDataset do
  end

  defmodule LLMStatsDashboard do
    use Incant.Dashboard

    title("LLM Proxy")

    variables do
      var(:range, :date_range, default: "24h")
      var(:provider, :multi_select, options: [:openai, :anthropic])
    end

    grid columns: 12, row_height: 8 do
      stat(:total_requests, span: 3, query: &Metrics.total_requests/2)
      timeseries(:requests_over_time, span: 9)

      table :slow_requests, span: 12 do
        column(:timestamp, label: "Timestamp", format: :datetime)
        column(:duration_ms, label: "Duration", format: :number)
      end

      chart :campaign_clicks, :line, span: 8 do
        dataset(CampaignDataset)
        x(:timestamp, bucket: :hour)
        y(:clicks)
        series(:campaign)
        drilldown(:campaign)
      end
    end
  end

  defmodule Admin do
    use Incant.Admin, service: :dashboard_test, version: "1"

    dashboard(LLMStatsDashboard)
  end

  test "rejects table columns outside table blocks" do
    assert_raise ArgumentError, ~r/column must be declared inside table_widget/, fn ->
      Code.compile_string("""
      defmodule Incant.DashboardTest.BadColumn#{System.unique_integer([:positive])} do
        use Incant.Dashboard

        grid do
          column :timestamp
        end
      end
      """)
    end
  end

  test "compiles dashboard metadata" do
    metadata = LLMStatsDashboard.__incant_dashboard__()

    assert metadata.module == LLMStatsDashboard
    assert metadata.title == "LLM Proxy"
    assert metadata.grid == [columns: 12, row_height: 8]

    assert Enum.map(metadata.variables, & &1.name) == [:range, :provider]

    assert Enum.map(metadata.widgets, & &1.id) == [
             :total_requests,
             :requests_over_time,
             :slow_requests,
             :campaign_clicks
           ]

    assert Enum.map(metadata.widgets, & &1.type) == [:stat, :timeseries, :table, :chart]
    assert hd(metadata.widgets).opts[:query] == (&Metrics.total_requests/2)

    table = Enum.find(metadata.widgets, &(&1.id == :slow_requests))
    assert table.opts[:span] == 12

    assert [
             %Incant.Dashboard.Column{name: :timestamp, opts: timestamp_opts},
             %Incant.Dashboard.Column{name: :duration_ms, opts: duration_opts}
           ] =
             table.opts[:columns]

    assert timestamp_opts == [label: "Timestamp", format: :datetime]
    assert duration_opts == [label: "Duration", format: :number]

    contract = Incant.Admin.describe(Incant.DashboardTest.Admin)

    contract_table =
      contract.dashboards
      |> hd()
      |> then(&Enum.find(&1.widgets, fn widget -> widget.id == "slow_requests" end))

    assert contract_table.opts.columns == [
             %{id: "timestamp", name: :timestamp, opts: %{label: "Timestamp", format: :datetime}},
             %{id: "duration_ms", name: :duration_ms, opts: %{label: "Duration", format: :number}}
           ]

    chart = List.last(metadata.widgets)
    assert chart.opts[:chart_type] == :line
    assert chart.opts[:dataset] == CampaignDataset
    assert chart.opts[:x] == {:timestamp, [bucket: :hour]}
    assert chart.opts[:y] == {:clicks, []}
    assert chart.opts[:series] == {:campaign, []}
    assert chart.opts[:drilldown] == {:campaign, []}
  end
end
