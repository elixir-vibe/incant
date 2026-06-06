# Design and theming


Incant renderers use semantic CSS variables instead of fixed Tailwind palette classes. Add the Incant source path to your Tailwind app and define the variables in your app CSS:

```css
@source "../deps/incant/lib";

:root {
  --incant-primary: var(--color-violet-600);
  --incant-bg: white;
  --incant-bg-elevated: white;
  --incant-bg-accented: var(--color-zinc-100);
  --incant-border: var(--color-zinc-200);
  --incant-text: var(--color-zinc-700);
  --incant-text-muted: var(--color-zinc-500);
  --incant-text-highlighted: var(--color-zinc-950);
}
```

See `Incant.Design.css_variables/0` and the playground's `assets/css/app.css` for the complete token set.

## Example theme

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
