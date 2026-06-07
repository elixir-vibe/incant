defmodule Incant.DatasetTest do
  use ExUnit.Case, async: true

  defmodule QuackSource do
  end

  defmodule CampaignPerformance do
    use Incant.Dataset, source: QuackSource

    title("Campaign Performance")
    from("campaign_daily")

    dimensions do
      dimension(:date, type: :date)
      dimension(:campaign)
      dimension(:keyword)
    end

    metrics do
      metric(:clicks, :sum)
      metric(:cost, :sum, format: :money)
      metric(:cpa, expr: "cost / nullif(orders, 0)", format: :money)
    end

    table density: :compact do
      group_by([:campaign])
      columns([:campaign, :clicks, :cost, :cpa])
      sort(:cost, :desc)
      heatmap([:cost, :cpa])
      drilldown(:campaign, group_by: [:keyword])
    end
  end

  defmodule Admin do
    use Incant.Admin

    dataset(CampaignPerformance)
  end

  test "compiles dataset metadata" do
    metadata = CampaignPerformance.__incant_dataset__()

    assert metadata.module == CampaignPerformance
    assert metadata.source == QuackSource
    assert metadata.title == "Campaign Performance"
    assert metadata.from == "campaign_daily"
    assert metadata.opts == [source: QuackSource]

    assert Enum.map(metadata.dimensions, & &1.name) == [:date, :campaign, :keyword]
    assert hd(metadata.dimensions).opts == [type: :date]

    assert Enum.map(metadata.metrics, & &1.name) == [:clicks, :cost, :cpa]
    assert Enum.map(metadata.metrics, & &1.aggregate) == [:sum, :sum, nil]
    assert List.last(metadata.metrics).expr == "cost / nullif(orders, 0)"
    assert List.last(metadata.metrics).opts == [format: :money]

    assert metadata.table.opts == [density: :compact]
    assert metadata.table.group_by == [:campaign]
    assert metadata.table.columns == [:campaign, :clicks, :cost, :cpa]
    assert metadata.table.sort == {:cost, :desc}
    assert metadata.table.heatmap == [:cost, :cpa]

    assert [%Incant.Dataset.Drilldown{dimension: :campaign, opts: [group_by: [:keyword]]}] =
             metadata.table.drilldowns
  end

  test "Incant.metadata/1 returns dataset metadata" do
    assert Incant.metadata(CampaignPerformance) == CampaignPerformance.__incant_dataset__()
  end

  test "admin modules can register datasets" do
    assert Incant.metadata(Admin).datasets == [CampaignPerformance]
  end
end
