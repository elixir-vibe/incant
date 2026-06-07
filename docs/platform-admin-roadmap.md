# Unified platform admin roadmap

Incant's long-term target is a unified, code-first operations UI for a deeply integrated Elixir platform: application records, analytical datasets, replay sessions, LLM traces, code facts, agent state, campaigns, and content should all be manageable through one admin surface.

The core principle stays the same:

> Incant DSL describes operational intent. Data sources own query execution. UI documents describe admin semantics. Adapters own rendering and interaction mechanics.

Incant should not become a generic component framework or a CRUD-only admin. The DSL should produce semantic tables, filters, actions, inspectors, widgets, and charts that adapters can render with world-class interaction details.

## Planned admin entity types

### Resources

Resources are record-oriented admin surfaces for Ecto schemas, custom repositories, or external APIs.

```elixir
defmodule Platform.Admin.Resources.LLMTrace do
  use Incant.Resource,
    schema: LLMProxy.Schemas.Trace,
    repo: Platform.Repo

  title "LLM Traces"

  table density: :compact do
    column :timestamp, format: :relative_time, sort: :desc
    column :provider, as: :badge
    column :model
    column :input_tokens, align: :right, format: :number
    column :output_tokens, align: :right, format: :number
    column :cost_usd, align: :right, format: :money
    column :duration_ms, align: :right, format: :duration
    column :session_id, link: :session

    heatmap :duration_ms
    row_detail :trace_preview

    action :open_session
    action :copy_curl
    action :retry_request, confirm: true
  end

  filters do
    date_range :timestamp, default: {:last, 24, :hours}
    multi_select :provider
    multi_select :model, depends_on: :provider
    range :cost_usd
    range :duration_ms
    text :session_id
  end
end
```

### Datasets

Datasets are analytical surfaces for QuackDB, Postgres, or external data sources. They describe dimensions, metrics, grouping, rollups, drilldowns, and chart/table bindings.

```elixir
defmodule Platform.Admin.Datasets.CampaignPerformance do
  use Incant.Dataset,
    source: Platform.Analytics.QuackDB

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
    metric :ctr, expr: clicks / nullif(impressions, 0), format: :percent
    metric :cpa, expr: cost / nullif(orders, 0), format: :money
    metric :roas, expr: revenue / nullif(cost, 0), format: :number
  end

  table do
    group_by [:campaign]
    columns [:campaign, :clicks, :cost, :orders, :revenue, :cpa, :roas]
    sort :cost, :desc
    heatmap [:cost, :orders, :roas]

    drilldown :campaign, group_by: [:ad_group]
    drilldown :ad_group, group_by: [:keyword]
  end
end
```

### Tools

Tools are custom task-oriented admin surfaces for workflows that are not table-first: code search, session replay, trace waterfalls, agent timelines, and similar interfaces.

```elixir
defmodule Platform.Admin.Tools.CodeSearch do
  use Incant.Tool

  title "Code Search"
  backend Exograph

  search do
    input :pattern, :code, language: :elixir
    facet :package
    facet :module
    facet :kind
  end

  results do
    column :qualified_name, link: true
    column :file
    column :line, align: :right
    preview :source, :code, language: :elixir
  end
end
```

## Realtime operations layer

Incant should support both historical analytics and live operational control. The admin should be able to show "what happened over the last 30 days" and "what is happening right now" in the same DSL.

Realtime surfaces should support:

- live visitor/session counters
- active pages, referrers, campaigns, devices, and locations
- active replay/session streams
- LLM request streams, queue state, model latency, and provider degradation
- `:telemetry` event streams, spans, metrics, and errors
- live chat conversations and operator/agent presence
- background Vibe agents monitoring app health, campaigns, user behavior, and support load
- agent-authored findings, recommendations, and executable action proposals

A realtime surface is not just a faster dashboard. It needs live subscriptions, backpressure, pause/resume, retention windows, and a clear split between observation and control.

```elixir
defmodule Platform.Admin.Realtime.MarketingOps do
  use Incant.Realtime

  title "Marketing realtime"

  stream :active_sessions do
    source Platform.Analytics.LiveSessions
    window 5, :minutes
    group_by [:campaign, :landing_page]
  end

  widget :active_visitors, :stat, metric: count_distinct(:session_id)
  widget :campaign_spend, :stat, metric: sum(:cost), refresh: 5_000

  action :pause_campaign do
    run &Platform.Direct.Actions.pause_campaign/2
    confirm true
  end

  agent :campaign_guardian do
    goal "Watch spend, conversion drops, and anomalous traffic in realtime"
    tools [:quackdb, :yandex_direct, :llm_proxy]
    can_propose [:pause_campaign, :lower_bid, :add_negative_keyword]
  end
end
```

## Table capabilities to build

Tables should support operational records and analytical data:

- semantic display formats: badge, money, duration, percent, relative time, JSON, code, diff, markdown
- compact and dense layouts through adapter/theme config
- row detail panels and expandable rows
- row, bulk, page, and contextual actions
- selected rows and bulk action state
- multi-column sorting
- saved views and shareable URLs
- heatmap cells and conditional formatting
- pinned/important columns
- exports: CSV, JSON, XLSX, and background exports for large datasets
- background query jobs for expensive analytics
- live-updating rows for realtime streams
- drilldowns from charts to tables to records

## Action model

Actions should be first-class semantic commands.

```elixir
actions do
  row :retry_request do
    label "Retry"
    confirm "Retry this request?"
    run &Platform.Admin.Actions.retry_trace/2
    refresh [:table, :widgets]
  end

  bulk :export_selected do
    label "Export selected"
    run &Platform.Admin.Exports.traces/2
    result :download
  end

  page :sync_yandex_direct do
    label "Sync Direct"
    run_async &Platform.Direct.Sync.run/1
    result :job
  end
end
```

Action result types should be semantic: refresh, navigate, download, toast, background job, open surface, or error. Core should not expose generic dialog primitives; adapters decide whether an action surface is a page, drawer, popover, or modal.

## Filters and transformers

Filters need to be controls plus query/data transformers, not only `where field = value`.

```elixir
filters do
  date_range :range, field: :timestamp
  multi_select :provider
  multi_select :model, depends_on: :provider
  range :cost_usd
  full_text :query

  transformer :attribution_window do
    control :select, options: ["1d", "7d", "30d"]
    apply &Platform.Admin.Filters.apply_attribution_window/3
  end
end
```

This is required for campaign attribution, cohort logic, replay/session joins, telemetry trace filters, live chat/support filters, code-search facets, access-controlled query modification, and QuackDB analytical queries with CTEs, joins, subqueries, custom ordering, and rollups.

## Telemetry traces

Incant should have a first-class telemetry/tracing admin surface. The expected source is `:telemetry`, but the UI contract should be generic enough for OpenTelemetry spans, app-specific trace rows, Vibe tool events, LLM proxy traces, and replay/session timelines.

```elixir
defmodule Platform.Admin.Traces.AppTelemetry do
  use Incant.TraceSource

  source :telemetry

  event [:phoenix, :endpoint, :stop] do
    measure :duration, unit: :native, format: :duration
    tag :route
    tag :status
  end

  event [:repo, :query, :stop] do
    measure :query_time, format: :duration
    tag :source
    tag :result
  end

  table do
    column :timestamp, format: :relative_time
    column :event
    column :duration, format: :duration, heatmap: true
    column :route
    column :status, as: :badge
    row_detail :span_payload
  end

  filters do
    date_range :timestamp, default: {:last, 1, :hour}
    multi_select :event
    range :duration
    text :route
  end
end
```

Trace UI needs timeline, waterfall, event table, JSON payload inspector, errors/exceptions, correlation IDs, and drilldowns to replay sessions, LLM traces, code locations, and agent actions.

## Chat with data and background agents

Incant should include a conversational operations layer on top of resources, datasets, charts, traces, and actions. The chat is not a generic chatbot floating above the UI; it is an admin-native Vibe agent surface with typed context and controlled actions.

```elixir
defmodule Platform.Admin.Agents.GrowthAnalyst do
  use Incant.Agent

  goal "Explain traffic, campaign performance, user behavior, and revenue changes"

  context do
    dataset Platform.Admin.Datasets.CampaignPerformance
    dataset Platform.Admin.Datasets.WebSessions
    resource Platform.Admin.Resources.ReplaySession
    resource Platform.Admin.Resources.LLMTrace
  end

  tools [:query, :chart, :drilldown, :export]
  can_propose [:pause_campaign, :change_bid, :add_negative_keyword]
  require_approval [:pause_campaign, :change_bid]
end
```

Agent surfaces should support:

- chat with the current table/dashboard/chart selection
- query generation over QuackDB and Ecto-backed resources
- background monitors with scheduled goals
- realtime anomaly detection
- action proposals with approval workflows
- audit trails for every agent observation and action
- handoff between human operators and agents

## Built-in live chat/support

Live chat should be another Incant domain, not a separate admin silo. Conversations, visitors, operators, agent runs, messages, transcripts, tags, SLAs, and escalations should be resources and realtime surfaces.

```elixir
defmodule Platform.Admin.Support.ChatInbox do
  use Incant.Tool

  title "Support inbox"

  stream :conversations do
    source Platform.Support.LiveChat
    status [:open, :pending]
  end

  actions do
    row :assign_to_me
    row :summarize_with_agent
    row :handoff_to_agent
    row :close_conversation
  end
end
```

This should share the Vibe agent stack: the same infrastructure that analyzes code and app telemetry can assist support, classify conversations, answer from project knowledge, and escalate to humans.

## Widgets and charts

Dashboard widgets should bind to resources or datasets and emit semantic specs.

```elixir
defmodule Platform.Admin.Dashboards.LLMUsage do
  use Incant.Dashboard

  title "LLM Usage"

  variables do
    date_range :range, default: {:last, 7, :days}
    multi_select :provider
    multi_select :model
  end

  grid columns: 12 do
    stat :requests, span: 3, metric: count(:trace_id)
    stat :cost, span: 3, metric: sum(:cost_usd), format: :money
    stat :p95_latency, span: 3, metric: p95(:duration_ms), format: :duration
    stat :error_rate, span: 3, metric: ratio(:errors, :requests), format: :percent

    chart :requests_over_time, :line, span: 8 do
      dataset Platform.Admin.Datasets.LLMUsage
      x :timestamp, bucket: :hour
      y count(:trace_id)
      series :provider
      drilldown to: Platform.Admin.Resources.LLMTrace
    end

    table :slow_requests, span: 4 do
      resource Platform.Admin.Resources.LLMTrace
      view :slow
    end
  end
end
```

Target chart specs: line, area, bar, stacked bar, pie, donut, heatmap, histogram, funnel, cohort/retention, sankey, geo, waterfall, and timeline. The default LiveView adapter can start simple; richer adapters such as LiveVue can use specialized chart libraries.

## Target integrations

Initial real-world vertical slices should come from the platform projects:

1. Plausible-style deep web analytics in QuackDB.
2. Yandex Direct campaign exports in QuackDB.
3. PhoenixReplay/Webvisor-like replayable sessions, including QuackDB-backed session tables.
4. LLMProxy usage, traces, messages, quotas, provider tokens, cost, and latency.
5. Exograph project code search, definitions, references, fragments, and call graph facts.
6. Vibe coding agent data: sessions, events, goals, memories, imports, subagent jobs, telemetry, and trajectory events.
7. Telemetry traces and application events captured through `:telemetry` and app-specific tracing.
8. Built-in live chat/support inbox with human operators and Vibe-backed agent support.
9. Generic application data such as orders, documents, edits, feedback, and session replays.

## Roadmap impact

This roadmap implies the next Incant architecture work should prioritize:

1. Stronger table metadata and table UI documents.
2. Row, bulk, page, and contextual action specs.
3. Dataset DSL and tabular protocol.
4. Filter controls plus transformer/filter dependency graph.
5. Chart and widget semantic specs.
6. Realtime surfaces and live stream subscriptions.
7. Telemetry/trace semantic surfaces.
8. Agent/chat surfaces with approval-gated control actions.
9. Tool/custom-surface DSL.
10. Generated starter modules for domain packs that users can customize.
