# Incant

[![Hex.pm](https://img.shields.io/hexpm/v/incant.svg)](https://hex.pm/packages/incant) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/incant)

Admin interfaces for Elixir and Phoenix. Describe resources, dashboards, datasets, actions, authorization, and themes in ordinary modules; Incant renders the LiveView application.

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource,
    schema: MyApp.Catalog.Product,
    repo: MyApp.Repo

  table do
    column :name, link: true
    column :status, as: :badge
    column :price, format: :money

    filter :status, :multi_select, options: [:draft, :active, :archived]
    search [:name]

    action :archive,
      callback: &MyApp.Catalog.archive_product/2,
      confirm: "Archive this product?",
      destructive: true
  end
end
```

That definition produces a searchable, sortable, filterable, paginated table with detail navigation, formatted cells, and a styled confirmation flow. No HEEx table or form templates are required.

## Why Incant

- **The admin stays in source control.** Resources, dashboards, datasets, policies, and themes are Elixir modules you can review, test, and deploy with the application.
- **Useful defaults, explicit escape hatches.** Ecto schemas get inferred fields and queries; custom query callbacks and data-source adapters cover joins, aggregates, APIs, and analytical stores.
- **More than CRUD.** Combine resource tables and forms with dashboard variables, stats, timeseries, charts, analytical datasets, drilldowns, page actions, bulk actions, and row inspectors.
- **Application-owned authorization.** Reuse Phoenix authentication assigns, scope Ecto queries or in-memory rows, override policies by surface, or delegate to Bodyguard.
- **One surface, local or remote.** Mount an admin inside its Phoenix application, or let services own their admin contracts and render them from a standalone Incant host over [SafeRPC](https://hexdocs.pm/safe_rpc).
- **A complete LiveView adapter.** Responsive navigation, dark mode, dense tables, accessible dialogs, multi-select controls, forms, filters, formatting, and theme tokens ship with the package.

## Installation

Add Incant to `mix.exs`:

```elixir
def deps do
  [
    {:incant, "~> 0.1"}
  ]
end
```

Run the installer in a Phoenix application:

```bash
mix deps.get
mix incant.install
```

It creates an admin root, sample resource, and theme, then patches the Phoenix router and Tailwind source when standard files are present.

Incant requires Elixir 1.19 or later and Phoenix LiveView 1.1 or later.

See [Getting Started](https://hexdocs.pm/incant/getting-started.html) for manual setup and asset integration.

## Library mode

Library mode is the default. Incant starts no supervision children; the host Phoenix application owns the endpoint, authentication, repo, and route.

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    repo: MyApp.Repo,
    theme: MyApp.Admin.Themes.Default,
    policy: MyApp.Admin.Policy,
    actor_assign: :current_scope

  resource MyApp.Admin.Resources.Product
  dashboard MyApp.Admin.Dashboards.Operations
end
```

Mount it in the host router:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Incant.Router

  scope "/", MyAppWeb do
    pipe_through [:browser, :require_authenticated_user]
    incant "/admin", MyApp.Admin
  end
end
```

Incant's browser behavior is an importable Volt package. Add dependency resolution and mount it from the host asset entry:

```elixir
# config/config.exs
config :volt, resolve_dirs: ["deps"]
```

```javascript
// assets/js/app.js
import { mountIncant } from "incant"

mountIncant()
```

Add the Tailwind source to the host CSS:

```css
@source "../deps/incant/lib";
```

See [Library Mode](https://hexdocs.pm/incant/library-mode.html) for router placement, assets, forms, authentication, and configuration.

## Standalone mode

Standalone Incant is a central admin host for service-owned surfaces. Each service keeps its schemas, repos, policies, queries, and actions in its own VM and exposes a portable contract over SafeRPC:

```elixir
defmodule Billing.Admin do
  use Incant.Admin,
    service: :billing,
    version: "1",
    repo: Billing.Repo,
    policy: Billing.Admin.Policy,
    rpc: true

  expose Billing.Invoices.Invoice
  dashboard Billing.Admin.Dashboards.Operations
end
```

The Incant host discovers configured service sockets, renders their resources and dashboards, and dispatches actions back to the owning service. Executable callbacks and repos never cross the transport boundary.

Enable the bundled endpoint in a standalone release:

```text
INCANT_SERVE=true
INCANT_HTTP_IP=127.0.0.1
INCANT_HTTP_PORT=4000
INCANT_SECRET_KEY_BASE=...
HOSTKIT_RPC_BINDINGS=/run/incant/rpc.etf
```

The host serves the LiveView admin and a semantic JSON API under `/incant`. It binds loopback by default and should sit behind operator authentication and a reverse proxy.

See [Standalone Mode](https://hexdocs.pm/incant/standalone-mode.html), [Distributed Services](https://hexdocs.pm/incant/distributed-services.html), and [Standalone Deployment](https://hexdocs.pm/incant/standalone-deployment.html).

## Resources and actions

A resource can use an Ecto schema, a custom query callback, or application-owned rows. Declarative metadata controls columns, filters, forms, search, details, and actions:

```elixir
defmodule MyApp.Admin.Resources.Ticket do
  use Incant.Resource,
    schema: MyApp.Support.Ticket,
    repo: MyApp.Repo

  table do
    column :subject, link: true
    column :priority, as: :badge
    column :inserted_at, format: :datetime

    filter :priority, :select, options: [:low, :normal, :high]
    filter :inserted_at, :date_range

    action :close, callback: &MyApp.Support.close_ticket/2, confirm: true

    actions do
      bulk :assign, callback: &MyApp.Support.assign_tickets/2
    end
  end

  form do
    field :subject
    field :priority, :select, options: [:low, :normal, :high]
  end
end
```

Incant formats compact numbers, durations, money, dates, relative times, IDs, booleans, and vocabulary terms consistently across surfaces.

See [Resources](https://hexdocs.pm/incant/resources.html).

## Dashboards and datasets

Dashboard widgets describe operations and analytics without embedding chart markup:

```elixir
defmodule MyApp.Admin.Dashboards.Operations do
  use Incant.Dashboard

  variables do
    var :range, :date_range, default: {:last, 24, :hours}
    var :provider, :multi_select, options: [:openai, :anthropic, :google]
  end

  grid columns: 12 do
    stat :requests, span: 3, format: :compact_number, query: &MyApp.Metrics.requests/2
    stat :latency, span: 3, format: :duration_ms, query: &MyApp.Metrics.latency/2
    timeseries :requests_over_time, span: 8, query: &MyApp.Metrics.timeline/2
    table :recent_failures, span: 4, query: &MyApp.Metrics.failures/2
  end
end
```

Datasets add dimensions, metrics, filters, grouping, heatmaps, and drilldowns over an `Incant.DataSource`. The source can execute against Ecto, an analytical database, or an external API.

See [Dashboards](https://hexdocs.pm/incant/dashboards.html) and [Datasets](https://hexdocs.pm/incant/datasets.html).

## Authorization and theming

Policies receive the current actor and semantic context:

```elixir
defmodule MyApp.Admin.Policy do
  use Incant.Policy
  import Ecto.Query

  def authorize(:view_admin, %{user: user}, _context), do: user.role in [:admin, :operator]
  def authorize(:edit, scope, %{row: row}), do: row.account_id == scope.user.account_id

  def scope_query(scope, _resource, query, _context) do
    from row in query, where: row.account_id == ^scope.user.account_id
  end
end
```

The LiveView adapter uses semantic CSS variables and theme metadata rather than a fixed Tailwind palette. Override tokens in host CSS, choose density, and provide an `Incant.Theme` module without replacing components.

See [Authorization](https://hexdocs.pm/incant/authorization.html) and [Themes and LiveView](https://hexdocs.pm/incant/themes-and-liveview.html).

## Documentation

- [Getting Started](https://hexdocs.pm/incant/getting-started.html)
- [Library Mode](https://hexdocs.pm/incant/library-mode.html)
- [Standalone Mode](https://hexdocs.pm/incant/standalone-mode.html)
- [Project Structure](https://hexdocs.pm/incant/project-structure.html)
- [Resources](https://hexdocs.pm/incant/resources.html)
- [Dashboards](https://hexdocs.pm/incant/dashboards.html)
- [Datasets](https://hexdocs.pm/incant/datasets.html)
- [Authorization](https://hexdocs.pm/incant/authorization.html)
- [Themes and LiveView](https://hexdocs.pm/incant/themes-and-liveview.html)
- [Distributed Services](https://hexdocs.pm/incant/distributed-services.html)
- [Standalone Deployment](https://hexdocs.pm/incant/standalone-deployment.html)
- [Configuration Cheatsheet](https://hexdocs.pm/incant/configuration.html)
- [Admin HTTP API](https://hexdocs.pm/incant/admin-http-api.html)
- [Architecture](https://hexdocs.pm/incant/architecture.html)
- [API reference](https://hexdocs.pm/incant/api-reference.html)

A runnable example lives in the [playground application](https://github.com/elixir-vibe/incant/tree/main/examples/playground).

## Development

```bash
mix deps.get
mix ci
```

Browser code is built, formatted, linted, type-checked, and tested through Volt. Node.js is not required.

## License

MIT © 2026 Danila Poyarkov
