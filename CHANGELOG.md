# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Security

- Require SafeRPC 0.1.15 or later for bounded frames, strict request validation, executable ETF rejection, and isolated listener failures.

## 0.1.1 - 2026-07-22

### Added

- Multi-select filters and dashboard variables now render as checkbox dropdowns instead of native stacked select boxes.

### Fixed

- Resource badges and dashboard table cells now apply the admin naming vocabulary, preserving terms such as `OpenAI` without changing unknown identifiers or model names.
- The Hex package now includes `package.json`, standalone configuration, and guides so Volt can resolve `import "incant"` from an installed dependency and packaged source can build the standalone release.

## [0.1.0] - 2026-07-20

First public release. Incant is experimental; the DSL and adapter contracts may
still evolve before 1.0.

### Added

- Compile-time DSLs for admin roots, resources, dashboards, themes, filters, forms, and table actions.
- Semantic UI document layer with a default Phoenix LiveView adapter for resources, details, tables, forms, filters, dashboards, and widgets.
- Query-backed and data-backed resource loading with search, filters, sorting, pagination, and detail lookup.
- Declarative service queries and Ecto table query helpers for portable (local or SafeRPC) execution.
- Ecto-aware form field inference and typed filter casting.
- Authorization policy behaviour with actor extraction, local policy overrides, row/query scoping, and Bodyguard-compatible return values.
- Styled confirm dialog for destructive/confirm actions (replaces native `window.confirm`).
- One-time secret reveal (`Incant.ActionResult.Reveal`) for values such as newly created API keys.
- Compact number, human duration, and full-value tooltip formatting for dashboard stats and table cells.
- Accessible dialogs (ARIA labelling, Escape to close) and full-contrast focus-visible rings.
- Standalone deployment mode (`serve?: true`) with a SafeRPC-backed service registry, plus the default library/embedded mode that starts no Incant children.
- Igniter-powered installer that generates starter admin files and patches Phoenix router/CSS when possible.
- Phoenix playground with Catalog, LLM, and Support examples.
- Focused documentation under `docs/`.

### Fixed

- Row action buttons now send their target id (LiveView value-property override), so delete/disable/remove actions work.
- Custom dashboard date ranges commit correctly and no longer crash on struct values.

[0.1.0]: https://github.com/elixir-vibe/incant/releases/tag/v0.1.0
