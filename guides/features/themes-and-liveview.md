# Themes and LiveView

Incant's default UI adapter renders semantic documents as Phoenix LiveView components. Host applications control CSS variables, density, naming, and browser integration without forking resource or dashboard components.

## LiveView adapter

Configure the default adapter globally:

```elixir
config :incant,
  ui_adapter: Incant.UI.Adapters.LiveView,
  density: :compact
```

Or override presentation for one admin root:

```elixir
config :incant, MyApp.Admin,
  density: :comfortable
```

The adapter renders:

- responsive admin navigation;
- resource tables, sorting, pagination, and row selection;
- detail inspectors and forms;
- filters and dashboard variables;
- stat, timeseries, chart, and table widgets;
- action results, confirmation dialogs, and one-time reveals;
- dataset tables, heatmaps, and drilldowns.

It consumes `Incant.UI.Document` nodes produced by the semantic region layer. Data loading and policy decisions happen before rendering.

## Tailwind source

Add Incant's dependency classes to host Tailwind scanning:

```css
@source "../deps/incant/lib";
```

Without this source, host builds can omit classes used only inside the dependency.

## Browser behavior

Let Volt resolve packages from dependencies:

```elixir
config :volt,
  resolve_dirs: ["deps"]
```

Import and mount Incant in the host entry:

```javascript
import { mountIncant } from "incant"

mountIncant()
```

The embedded entry does not connect a LiveSocket. It adds behavior around the LiveView markup already rendered by the host:

- light/dark theme persistence;
- mobile navigation;
- filter and date-range controls;
- styled confirmation and secret-reveal dialogs;
- clipboard actions;
- combobox and selection interactions.

Standalone Incant uses the `incant/standalone` entry, which creates the bundled endpoint's LiveSocket before mounting the same behavior.

## CSS variables

The adapter uses semantic variables instead of fixed Tailwind palette colors. Define them in host CSS:

```css
:root {
  --incant-primary: var(--color-violet-600);
  --incant-bg: white;
  --incant-bg-elevated: white;
  --incant-bg-muted: var(--color-zinc-50);
  --incant-bg-accented: var(--color-zinc-100);
  --incant-border: var(--color-zinc-200);
  --incant-border-muted: var(--color-zinc-100);
  --incant-text: var(--color-zinc-700);
  --incant-text-muted: var(--color-zinc-500);
  --incant-text-highlighted: var(--color-zinc-950);
}

.dark {
  --incant-bg: var(--color-zinc-950);
  --incant-bg-elevated: var(--color-zinc-900);
  --incant-bg-muted: color-mix(in srgb, var(--color-zinc-900) 65%, black);
  --incant-bg-accented: var(--color-zinc-800);
  --incant-border: var(--color-zinc-700);
  --incant-border-muted: var(--color-zinc-800);
  --incant-text: var(--color-zinc-300);
  --incant-text-muted: var(--color-zinc-500);
  --incant-text-highlighted: white;
}
```

Use `Incant.Design.css_variables/0` and `assets/css/app.css` in the package source for the complete current token set.

## Theme modules

Theme metadata describes palette, density support, tokens, tables, and charts:

```elixir
defmodule MyApp.Admin.Themes.Default do
  use Incant.Theme

  css_vars_prefix "--incant"
  palette :zinc
  accent :violet
  density [:compact, :comfortable, :spacious]

  tokens do
    color :background, "var(--incant-bg)"
    radius :md, "var(--incant-radius-md)"
    spacing :table_row_height, "var(--incant-table-row-height)"
    font :sans, "var(--incant-font-sans)"
  end

  table do
    sticky_header true
    row_height "var(--incant-table-row-height)"
    zebra true
  end

  charts do
    chart_palette [:blue, :violet, :emerald, :amber, :rose]
  end
end
```

Register it on the admin root:

```elixir
use Incant.Admin,
  theme: MyApp.Admin.Themes.Default
```

Keep visual values in CSS variables when they need responsive, media-query, or dark-mode behavior. Use theme metadata when Incant renderers need semantic choices.

## Naming vocabulary

Admin-specific vocabulary keeps domain terms consistent in navigation, options, badges, and dashboard data cells:

```elixir
use Incant.Admin,
  naming: [
    terms: %{
      api: "API",
      openai: "OpenAI",
      oauth: "OAuth",
      llm: "LLM"
    }
  ]
```

Unknown data-cell strings remain unchanged so identifiers and model names such as `gpt-4.1` are not title-cased accidentally.

## Formatting

Use column or widget format metadata for values that are not plain labels:

```elixir
column :tokens, format: :compact_number
column :latency_ms, format: :duration_ms
column :cost_usd, format: :money
column :inserted_at, format: :datetime
column :request_id, format: :id
```

Formatting is shared across semantic regions so a duration or amount reads consistently in resource tables and dashboard widgets.

## Accessibility

The default adapter includes keyboard-visible focus rings, labelled dialogs, Escape handling, native form controls where appropriate, and semantic buttons and links. Preserve those behaviors when overriding CSS. Custom adapter implementations are responsible for equivalent semantics and interaction states.
