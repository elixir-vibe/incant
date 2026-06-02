defmodule Playground.Admin.Theme do
  @moduledoc false

  use Incant.Theme

  css_vars_prefix("--incant-playground")
  palette(:zinc)
  accent(:violet)
  density([:compact, :comfortable, :spacious])

  tokens do
    color(:background, "var(--incant-playground-background)")
    color(:surface, "var(--incant-playground-surface)")
    color(:primary, "var(--incant-playground-primary)")
    radius(:md, "var(--incant-playground-radius-md)")
    spacing(:table_row_height, "var(--incant-playground-table-row-height)")
    font(:sans, "var(--incant-playground-font-sans)")
  end

  table do
    sticky_header(true)
    row_height("var(--incant-playground-table-row-height)")
    zebra(true)
  end

  charts do
    chart_palette([:blue, :violet, :emerald, :amber, :rose])
  end
end
