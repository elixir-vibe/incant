# Incant Plan

Incant is an Elixir/Phoenix-native control plane for resources, content, analytics, dashboards, and operations. It should feel like a spell cast over an application: ordinary Ecto schemas, content files, telemetry streams, external APIs, and business datasets become a polished, customizable LiveView admin and headless CMS.

## Product thesis

Incant is not a CRUD toy. It is a code-first framework for building serious internal products:

- ActiveAdmin/Backpex-style resource administration
- Payload/Strapi-style headless CMS and editorial workflows
- Grafana-style dashboards and analytical widgets
- Retool-style operational tools, but compiled into normal Elixir modules
- Livebook/Kino-powered exploration as an optional development layer
- Igniter-powered generation and project integration

The core rule: Incant describes admin intent; Ecto remains the language of data truth.

## Unified platform admin target

Incant should become the unified admin UI for a deeply integrated Elixir/Vibe platform, not just a CRUD generator. The planned integration targets are:

1. Plausible-style deep web analytics loaded through QuackDB.
2. Yandex Direct campaign exports and performance analysis in QuackDB.
3. PhoenixReplay/Webvisor-like replayable sessions with session tables in QuackDB.
4. LLMProxy usage, traces, messages, quotas, provider tokens, latency, and cost analytics.
5. Exograph code search over definitions, references, fragments, and call graph facts.
6. Vibe coding agent data: sessions, events, goals, memories, imports, subagent jobs, telemetry, and trajectories.
7. Telemetry traces and application events captured through `:telemetry` and app-specific tracing.
8. Built-in live chat/support inbox with human operators and Vibe-backed agent support.
9. Generic application data such as orders, documents, edits, feedback, and replay sessions.

The DSL should describe semantic operations surfaces for those domains: resources, analytical datasets, and custom tools. Adapters own the interaction mechanics and visual implementation.

See [docs/platform-admin-roadmap.md](docs/platform-admin-roadmap.md) for the concrete table, action, filter, widget, chart, dataset, and tool DSL direction.

## Inspirations to study

- Payload CMS: code-first config, generated admin, field hooks, access control, versions, drafts, autosave, live preview, custom components.
- Strapi: content-type builder, RBAC matrix, draft/publish tabs, content history, admin widgets, plugin SDK, OpenAPI.
- Backpex: LiveView resources, field types, filters, actions, metrics, Igniter installer direction.
- Kaffy: ActiveAdmin/Django Admin lineage, resource discovery, dashboard widgets, custom pages and actions.
- LiveAdmin: low-config LiveView admin, Ecto prefixes, embedded schema editing, PubSub notifications.
- AshAdmin: DSL-backed admin for Ash resources.
- Grafana: variable-driven dashboards, panels, drilldowns, refresh, alerting.
- Kino/Livebook: interactive exploration and smart-cell generation, not the production UI runtime.

## Core pillars

### Resources

Resource modules expose Ecto schemas or custom data sources through configurable LiveView admin screens.

```elixir
defmodule MyApp.Admin.OrderResource do
  use Incant.Resource,
    schema: MyApp.Orders.Order,
    repo: MyApp.Repo

  query &MyApp.Admin.Queries.orders_index/2
  update &MyApp.Orders.admin_update_order/3

  table do
    column :number, link: true
    column :customer, value: & &1.customer.email
    column :total, format: :money
    column :status, as: :badge

    filter :status, :select
    filter :inserted_at, :date_range
    search &MyApp.Admin.Filters.order_search/3
  end
end
```

Resource features:

- full Ecto query callbacks
- sorting, filtering, search, pagination
- custom preloads and batch-loaded virtual fields
- row actions and bulk actions
- nested resources and relationship panels
- inline editing
- saved views
- audit trail integration
- field-level authorization
- total LiveView escape hatches

### Tables and datasets

Tables must support analytical workloads, not only records. Incant should handle orders, visits, campaign stats, LLM requests, imported Yandex Direct data, Plausible events, Metrica sessions, and derived funnel datasets.

```elixir
dataset :campaign_funnel do
  query &MyApp.Marketing.Funnel.query/2

  dimensions do
    dimension :utm_source
    dimension :utm_campaign
    dimension :landing_page
    dimension :direct_keyword
  end

  metrics do
    metric :visits, count_distinct(:visit_id)
    metric :orders, count_distinct(:order_id)
    metric :revenue, sum(:order_total)
    metric :ad_spend, sum(:direct_cost)
    metric :cpa, expr(:ad_spend / nullif(:orders, 0))
    metric :roas, expr(:revenue / nullif(:ad_spend, 0))
  end
end
```

Needed table capabilities:

- saved views and shareable URLs
- URL-persistent table state for filters, search, sorting, pagination, and selected views
- row-based and column-based data ingestion through a tabular protocol inspired by Dashbit's `Table.Reader`
- date ranges and global variables
- grouping, pivoting, dimensions, metrics
- computed columns and heatmaps
- expandable rows and detail panels
- drilldowns from charts to tables to records
- multiple view modes: table, cards, kanban, and custom LiveComponent layouts
- multi-column sorting with explicit DSL support
- export to CSV/JSON/XLSX, with background jobs for large exports
- background query jobs for expensive reports
- data-source capability negotiation

### Dashboards and widgets

Widgets are first-class modules with a Grafana-style DSL.

```elixir
defmodule MyApp.Admin.LLMStatsDashboard do
  use Incant.Dashboard

  title "LLM Proxy"

  variables do
    var :range, :date_range, default: {:last, 24, :hours}
    var :provider, :multi_select, options: [:openai, :anthropic, :google]
    var :model, :select, source: query(:models)
  end

  grid columns: 12, row_height: 8 do
    stat :total_requests, span: 3
    stat :total_cost, span: 3
    stat :avg_latency, span: 3
    stat :error_rate, span: 3
    timeseries :requests_over_time, span: 8
    table :slow_requests, span: 4
  end
end
```

Widget types:

- stat
- table
- time series
- bar/area/line charts
- pie/donut
- heatmap
- histogram
- funnel
- cohort/retention
- sankey
- geo map
- logs/event stream
- trace waterfall
- markdown
- custom LiveComponent

Each widget should support refresh, cache TTL, export, drilldown, and eventually alert rules.

### Content and CMS

Incant should support database-backed, Git-backed, and hybrid content.

```elixir
git_content MyApp.Docs do
  repo "git@github.com:company/docs.git"
  branch "main"
  root "content"
  type :markdown, engine: MDEx

  frontmatter do
    field :title, :string
    field :description, :string
    field :tags, {:array, :string}
    field :published, :boolean
  end

  workflow do
    edit_mode :branch
    publish_mode :pull_request
    preview_deploy true
  end
end
```

CMS features:

- markdown via MDEx
- blocks and reusable sections
- uploads and media library
- drafts, autosave, versions, diffs, restore
- scheduled publishing and content releases
- preview URLs and live preview
- localization per resource and field
- field comments and editorial annotations
- Git-backed editing through branches and PRs
- database-to-Git sync for portable content

### Filters and transformers

Simple filters should be pleasant, but complex filters must receive full query control. LiveTable's transformer idea is the right model: a filter can transform the whole query and maintain URL-persistent state, instead of only adding a single field condition.

```elixir
table do
  filter :status, :select, options: [:draft, :published]
  filter :price, :range
  filter :active, :boolean

  transformer :sales_performance do
    query &MyApp.Admin.Filters.sales_performance/3
  end

  transformer :attribution_window do
    query fn query, params, ctx ->
      query
      |> join(:left, ...)
      |> group_by(...)
      |> having(...)
    end
  end
end
```

Transformers are critical for marketing analytics, Yandex Direct/Metrica/Plausible joins, rank filters, attribution windows, cohort logic, access-controlled query modification, and any query that needs joins, CTEs, fragments, subqueries, aggregations, or custom ordering.

### Fields

Fields are behaviours with display, input, filtering, validation, import/export, and authorization hooks.

```elixir
field :prompt_template, :code do
  language :markdown
  variables [:user_name, :order_id, :locale]
  preview MyApp.Admin.PromptPreview
  validate &MyApp.Prompts.validate_template/1
end
```

Core fields:

- text, textarea, markdown, rich text
- code and JSON editors
- uploads, images, galleries
- relationship and polymorphic relationship
- enum, money, color, date range, map point
- tags, slug, computed, virtual, encrypted
- localized fields
- embedded schemas
- arrays/repeaters
- content blocks

### Tabular data protocol

Incant needs a normalized table-data boundary before rendering, exporting, charting, or transforming results. Dashbit's `table` package is a strong reference: it separates row-based and column-based traversal, exposes metadata such as columns and optional count, and uses a protocol so different data structures can be treated as tabular.

Incant should either depend on `table` or provide a compatible internal protocol:

```elixir
Incant.Tabular.init(data)
Incant.Tabular.to_rows(data, only: [:model, :requests, :cost])
Incant.Tabular.to_columns(data)
Incant.Tabular.metadata(data)
```

Supported shapes should include:

```elixir
[%{model: "gpt-4.1", requests: 1200}, %{model: "claude", requests: 800}]
%{model: ["gpt-4.1", "claude"], requests: [1200, 800]}
[{"model", ["gpt-4.1", "claude"]}, {"requests", [1200, 800]}]
```

This boundary lets resource tables, dashboard table widgets, CSV/XLSX export, analytics datasets, and external API adapters share one representation without forcing everything through Ecto.

### Data sources

Incant resources and datasets should not be limited to Ecto schemas.

```elixir
datasource :ecto, MyApp.Repo
datasource :plausible, MyApp.Analytics.Plausible
datasource :yandex_metrica, MyApp.Analytics.Metrica
datasource :yandex_direct, MyApp.Marketing.Direct
datasource :llm_proxy, MyApp.LLMProxy.AdminSource
datasource :clickhouse, MyApp.Analytics.ClickHouse
```

A data source declares capabilities: filter, sort, paginate, aggregate, group, timeseries, search, export, live_update, mutate, drilldown.

### Policies

Authorization must be one policy system for UI and APIs.

```elixir
defmodule MyApp.Admin.Policies.PostPolicy do
  use Incant.Policy

  role :admin do
    allow :all
  end

  role :editor do
    allow [:read, :create, :update]
    allow :publish, where: [status: :draft]
    deny :delete
  end

  role :author do
    allow :read
    allow [:update, :delete], if: &owned_by_current_user?/2
    field :internal_notes, deny: :read
  end
end
```

The admin UI should dynamically hide, disable, or redact resources, actions, rows, and fields using the same policy rules that protect mutations and APIs.

### Theme system

Tailwind 4 and CSS variables are core architecture, not an afterthought.

```elixir
defmodule MyApp.Admin.Theme do
  use Incant.Theme

  css_vars_prefix "--incant"

  palette :zinc
  accent :violet

  density [:compact, :comfortable, :spacious]

  table do
    sticky_header true
    row_height "var(--incant-table-row-height)"
    zebra true
  end

  charts do
    palette [:blue, :violet, :emerald, :amber, :rose]
  end
end
```

Requirements:

- Tailwind 4 `@theme` support
- documented CSS variable contract
- dark mode and system mode
- per-tenant and per-user theming
- density controls
- white labeling
- component variants
- isolated embeddable widget theme context

### Plugins

Plugins package reusable admin capabilities.

```elixir
defmodule LLMProxy.Admin do
  use Incant.Plugin

  dashboard LLMProxy.Admin.Dashboard
  resource LLMProxy.Admin.RequestResource
  resource LLMProxy.Admin.ModelResource
  resource LLMProxy.Admin.ProviderResource
end
```

First plugin targets:

- `llm_proxy`: request stats, model/provider costs, latency, errors, traces.
- example application data: orders, visits, campaign attribution, marketing funnel analytics.

First-party plugin ideas:

- media library
- versions/drafts
- localization
- API tokens
- webhooks
- audit log
- Oban
- markdown/MDEx
- search
- AI embeddings
- redirects
- SEO
- SSO
- multi-tenancy
- import/export

### Igniter

Igniter is mandatory for developer experience.

```sh
mix incant.install
mix incant.gen.resource MyApp.Orders.Order
mix incant.gen.dashboard LLMProxy.Admin.Dashboard
mix incant.gen.widget total_cost --type stat
mix incant.gen.content Page --blocks hero,gallery,markdown,cta
mix incant.gen.policy MyApp.Blog.Post
```

Installers should modify router, assets, Tailwind sources, config, layouts, resource modules, migrations, tests, and examples safely and idempotently.

### Kino and Livebook

Kino is optional and development-oriented.

```elixir
Incant.Kino.render(MyApp.Admin.MarketingDashboard)
Incant.Kino.render_widget(MyApp.Admin.Widgets.LLMUsage)
Incant.Kino.inspect_resource(MyApp.Admin.OrderResource)
```

Principle: Kino for exploration. LiveView for production. Shared DSL for both.

## MVP path

### Milestone 1: Metadata core

- `Incant.Admin`
- `Incant.Resource`
- `Incant.Table`
- `Incant.Column`
- `Incant.Filter`
- `Incant.Dashboard`
- `Incant.Widget`
- `Incant.Theme`
- minimal macro DSL that emits inspectable metadata

### Milestone 2: LiveView renderer

- admin shell
- dashboard page
- resource index page
- table rendering
- simple filters
- URL-persistent resource and dashboard state
- date range variable
- widget grid
- Tailwind 4/CSS variable contract

### Milestone 3: Tabular data and Ecto integration

- tabular protocol inspired by `Table.Reader`
- row-based and column-based traversal
- metadata with columns and optional count
- resource `data` callback for non-Ecto playground data
- query callback
- pagination
- sorting and multi-column sorting metadata
- filters as Ecto callbacks
- transformer filters with full query control
- search callback
- custom select/preload support
- batch virtual fields

### Milestone 4: Operational actions and richer tables

- row, bulk, page, and contextual actions
- semantic action results: refresh, navigate, download, toast, background job, open surface, error
- row detail panels and expandable rows
- selected-row state and bulk action lifecycle
- semantic display formats: badge, money, duration, percent, relative time, JSON, code, diff, markdown
- heatmap cells and conditional formatting
- saved views and shareable URLs
- exports for CSV, JSON, XLSX, and background exports

### Milestone 5: Dataset and chart vertical slice

Build QuackDB-backed analytics for Plausible-style events and Yandex Direct campaign exports:

- `Incant.Dataset` DSL
- dimensions and metrics
- computed metrics and rollups
- dimensions/metrics table
- date range, campaign, source, and keyword filters
- ROAS/CPA/conversion metrics
- chart specs for line, area, bar, stacked bar, heatmap, histogram, funnel, cohort/retention, sankey, geo, waterfall, and timeline
- drilldowns from chart to dataset table to resource records
- background query jobs for expensive reports

### Milestone 6: LLM and replay vertical slices

Build LLMProxy and PhoenixReplay integrations:

- LLM traces, usage, messages, quotas, API keys, and provider token resources
- total requests, cost, latency, error-rate, and requests-over-time widgets
- slow requests table and trace inspector
- replay session table
- replay timeline tool surface
- session/event filters and replay-to-application drilldowns

### Milestone 7: Realtime, telemetry, and live operations

- realtime surfaces for active visitors, active sessions, campaign state, queue state, provider health, and live app events
- `:telemetry` trace source DSL
- timeline, waterfall, event table, JSON payload inspector, and correlation IDs
- live stream subscriptions with pause/resume, retention windows, and backpressure
- drilldowns from telemetry traces to replay sessions, LLM traces, code locations, and agent actions

### Milestone 8: Code and agent vertical slices

Build Exograph and Vibe integrations:

- code search tool surface
- definitions, references, fragments, files, packages, and call graph resources
- Vibe sessions, events, goals, memories, imports, subagent jobs, telemetry, and trajectory resources
- agent operations dashboard
- chat with data over resources, datasets, charts, traces, and selected rows
- background monitoring agents with approval-gated control actions
- cross-links between code facts, sessions, tool calls, generated changes, and production telemetry

### Milestone 9: Built-in live chat/support vertical slice

- live chat/support inbox tool surface
- conversations, visitors, operators, messages, transcripts, tags, SLAs, and escalations as resources
- realtime presence and active conversation streams
- Vibe-backed support agents for summarization, suggested replies, classification, and handoff
- shared audit trail for human and agent actions

### Milestone 10: Application/content vertical slice

- MDEx markdown field
- Git-backed content resource
- frontmatter editing
- branch/PR publishing workflow
- preview URLs

## Non-goals

- Replacing Ecto with a weaker query language.
- Runtime click-built production schemas as the default source of truth.
- Making Kino a production dependency.
- Hiding Phoenix/LiveView behind opaque magic.
- Shipping a pretty CRUD toy before validating serious analytics and operational workflows.

## Package shape

Start as one package:

```elixir
{:incant, "~> 0.1"}
```

Potential future split:

```elixir
{:incant_core, "~> 0.1"}
{:incant_live, "~> 0.1"}
{:incant_ecto, "~> 0.1"}
{:incant_igniter, "~> 0.1"}
{:incant_kino, "~> 0.1"}
{:incant_content, "~> 0.1"}
{:incant_analytics, "~> 0.1"}
```

Keep the first public release focused: metadata DSL + LiveView resource table + dashboard widget grid + Ecto callbacks + Tailwind theme contract.
