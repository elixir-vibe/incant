# Incant

Incant is an Elixir/Phoenix-native control plane for serious admin, content, analytics, dashboards, and operations work.

It is currently experimental and in its first implementation pass. The package provides compile-time DSLs that produce inspectable metadata for resources, dashboards, themes, admin roots, and data sources, plus a generic LiveView renderer for tables, details, forms, filters, dashboards, and row actions.

See [PLAN.md](PLAN.md) for the full product thesis and roadmap, [CONVENTIONS.md](CONVENTIONS.md) for the recommended application structure, and [REFERENCES.md](REFERENCES.md) for external packages and products informing the design.

## Quick start

Generate starter files in a Phoenix app:

```sh
mix incant.install
```

The Igniter-powered installer creates an admin root, a sample resource, a theme, and patches the Phoenix router/app CSS when it can detect them. See [docs/install.md](docs/install.md) for details and fallback snippets.

## Playground

A Phoenix playground lives in [`examples/playground`](examples/playground). It uses the local Incant package and VibeKit, then defines realistic Catalog and LLM contexts, admin resources, an operations dashboard, and a theme contract.

```sh
cd examples/playground
mix setup
mix phx.server
```

Visit `/admin` to see the generic LiveView renderer.

## Minimal resource

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource,
    schema: MyApp.Catalog.Product,
    repo: MyApp.Repo

  table do
    column :name, link: true
    column :status, as: :badge
    filter :status, :select, options: [:draft, :active, :archived]
    action :edit
  end
end
```

## Minimal dashboard

```elixir
defmodule MyApp.Admin.Dashboards.Operations do
  use Incant.Dashboard

  title "Operations"

  grid columns: 12 do
    stat :total_requests, span: 3, query: &MyApp.Admin.Metrics.total_requests/2
    table :slow_requests, span: 6, query: &MyApp.Admin.Metrics.slow_requests/2
  end
end
```

## Guides

- [Installation](docs/install.md)
- [Resources, filters, forms, actions, and query-backed data](docs/resources.md)
- [Dashboards and variables](docs/dashboards.md)
- [Authorization and policy scoping](docs/authorization.md)
- [Design tokens and themes](docs/design.md)
- [Live component structure](docs/live-components.md)
- [Architecture](docs/architecture.md)
- [Release checklist](docs/release-checklist.md)

## Development

This project was bootstrapped with VibeKit.

```sh
mix deps.get
mix test
mix ci
```

## Package name

`incant` was checked as available on Hex.pm before project creation.
