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

## Direction

The long-term direction is a unified, code-first operations UI for a deeply integrated Elixir platform: application records, analytical datasets, LLM traces, code facts, and content managed through one admin surface. See [docs/platform-admin-roadmap.md](docs/platform-admin-roadmap.md) for the roadmap and [REFERENCES.md](REFERENCES.md) for the external products informing the design.

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
