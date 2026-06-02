# Incant References

## Payload CMS

Reference: https://payloadcms.com/docs

Useful ideas:

- code-first content/resource configuration
- generated admin UI from data shape
- custom components as escape hatches
- field-level hooks and access control
- drafts, versions, autosave, live preview
- localization and media management

## Strapi

Reference: https://docs.strapi.io

Useful ideas:

- content-type builder experience
- RBAC matrix
- draft/publish tabs
- content history
- admin homepage widgets
- plugin SDK and OpenAPI

For Incant, schema/content builders should generate code and migrations through Igniter rather than becoming the production source of truth.

## Backpex, Kaffy, LiveAdmin, AshAdmin

Useful Elixir references:

- Backpex: LiveView resources, customizable fields, filters, actions, metrics, Igniter direction.
- Kaffy: ActiveAdmin/Django Admin lineage, resource discovery, dashboards, custom pages/actions.
- LiveAdmin: low-config LiveView admin, Ecto prefixes, PubSub notifications, embedded schema editing.
- AshAdmin: DSL-backed admin for Ash resources.

## Dashbit Table

Reference: https://table.hexdocs.pm/Table.html

Useful ideas:

- protocol-based unified access to tabular data
- support row-based and column-based traversal
- metadata with columns and optional count
- lazy enumerable traversal
- `only:` column selection

Incant should use this idea for a normalized table-data boundary shared by resource tables, dashboard table widgets, exports, analytics datasets, and external API data sources.

## LiveTable

Reference: https://live-table.hexdocs.pm/readme.html
Reference: https://live-table.hexdocs.pm/transformers.html

Useful ideas:

- advanced filtering taxonomy: text, range, select, boolean
- multi-column sorting
- pagination and infinite scroll options
- table and card modes
- export support
- URL-persistent state
- transformers that receive the full Ecto query and filter state

The transformer idea is especially important for Incant because serious admin/analytics work needs joins, aggregations, subqueries, CTEs, fragments, custom ordering, access-control transforms, and cross-source analytics.
