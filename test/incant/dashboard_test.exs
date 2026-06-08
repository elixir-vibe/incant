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
      var(:range, :date_range, default: {:last, 24, :hours})
      var(:provider, :multi_select, options: [:openai, :anthropic])
    end

    grid columns: 12, row_height: 8 do
      stat(:total_requests, span: 3, query: &Metrics.total_requests/2)
      timeseries(:requests_over_time, span: 9)
      table(:slow_requests, span: 12)

      chart :campaign_clicks, :line, span: 8 do
        dataset(CampaignDataset)
        x(:timestamp, bucket: :hour)
        y(:clicks)
        series(:campaign)
        drilldown(:campaign)
      end
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

    chart = List.last(metadata.widgets)
    assert chart.opts[:chart_type] == :line
    assert chart.opts[:dataset] == CampaignDataset
    assert chart.opts[:x] == {:timestamp, [bucket: :hour]}
    assert chart.opts[:y] == {:clicks, []}
    assert chart.opts[:series] == {:campaign, []}
    assert chart.opts[:drilldown] == {:campaign, []}
  end
end
