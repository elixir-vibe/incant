# Datasets

Incant datasets describe analytical data: dimensions, metrics, default table views, heatmaps, and drilldowns. They are metadata-first. Data-source adapters own SQL generation and execution for QuackDB, Postgres, external APIs, or other analytical backends.

```elixir
defmodule MyApp.Admin.Datasets.CampaignPerformance do
  use Incant.Dataset, source: MyApp.Analytics.QuackDB

  title "Campaign Performance"
  from "campaign_daily"

  dimensions do
    dimension :date, type: :date
    dimension :source
    dimension :campaign
    dimension :ad_group
    dimension :keyword
    dimension :landing_page
  end

  metrics do
    metric :impressions, :sum
    metric :clicks, :sum
    metric :orders, :sum
    metric :cost, :sum, format: :money
    metric :revenue, :sum, format: :money
    metric :ctr, expr: "clicks / nullif(impressions, 0)", format: :percent
    metric :cpa, expr: "cost / nullif(orders, 0)", format: :money
    metric :roas, expr: "revenue / nullif(cost, 0)", format: :number
  end

  table density: :compact do
    group_by [:campaign]
    columns [:campaign, :clicks, :cost, :orders, :revenue, :cpa, :roas]
    sort :cost, :desc
    heatmap [:cost, :orders, :roas]

    drilldown :campaign, group_by: [:ad_group]
    drilldown :ad_group, group_by: [:keyword]
  end
end
```

Register datasets on an admin root:

```elixir
defmodule MyApp.Admin do
  use Incant.Admin

  dataset MyApp.Admin.Datasets.CampaignPerformance
end
```

Build and run normalized dataset queries through the configured source:

```elixir
query =
  Incant.Dataset.query(MyApp.Admin.Datasets.CampaignPerformance,
    filters: %{"range" => "30d"},
    page: 1,
    page_size: 50
  )

{:ok, result} = Incant.Dataset.run(MyApp.Admin.Datasets.CampaignPerformance, filters: query.filters)
```

Data sources implement the `Incant.DataSource` query callback and receive `%Incant.Query{}` with `from`, dimensions, metrics, groupings, columns, filters, sort, pagination, variables, and context. Incant normalizes source rows into `%Incant.Result{}`.

Rendering, chart binding, saved views, and drilldown routing are planned follow-up work.
