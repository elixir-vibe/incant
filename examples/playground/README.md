# Incant playground

This Phoenix app exercises Incant against a small but realistic admin domain.

## Run

```sh
mix setup
mix phx.server
```

Open `/admin`.

## Domain contexts

The playground keeps admin definitions separate from domain data:

- `Playground.Catalog` exposes products.
- `Playground.LLM` exposes LLM request data and dashboard metrics.
- `Playground.Support` exposes tickets with an Ecto changeset.

## Admin structure

```text
lib/playground/admin.ex
lib/playground/admin/resources/product.ex
lib/playground/admin/resources/llm_request.ex
lib/playground/admin/resources/ticket.ex
lib/playground/admin/dashboards/llm.ex
lib/playground/admin/themes/default.ex
```

The admin demonstrates:

- data-backed resources
- table columns, filters, row actions, and detail pages
- dashboard stat, timeseries, and table widgets
- form validation and save flow through a small repo stub
- semantic CSS variables via the theme

## Authorization

Authorization behavior is covered by Incant's library tests. The playground keeps one clean `/admin` surface focused on the main admin experience.
