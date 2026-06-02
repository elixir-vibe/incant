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
- `docgen_ex`: orders, visits, campaign attribution, marketing funnel analytics.

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

### Milestone 4: Real plugin vertical slice

Build `llm_proxy` admin integration:

- requests resource
- provider/model filters
- request detail
- total requests widget
- cost widget
- latency widget
- error-rate widget
- requests-over-time chart
- slow requests table

### Milestone 5: Analytics vertical slice

Build `docgen_ex` marketing analytics:

- orders resource
- visits dataset
- campaigns dataset
- funnel dashboard
- dimensions/metrics table
- date range and campaign filters
- ROAS/CPA/conversion metrics
- drilldowns

### Milestone 6: Content vertical slice

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
