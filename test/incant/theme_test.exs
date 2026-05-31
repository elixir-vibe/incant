defmodule Incant.ThemeTest do
  use ExUnit.Case, async: true

  defmodule AdminTheme do
    use Incant.Theme

    css_vars_prefix("--spell")
    palette(:zinc)
    accent(:violet)
    density([:compact, :comfortable])

    tokens do
      color(:background, "var(--spell-background)")
      radius(:md, "var(--spell-radius-md)")
      spacing(:table_row_height, "var(--spell-table-row-height)")
      font(:sans, "var(--spell-font-sans)")
    end

    table do
      sticky_header(true)
      row_height("var(--spell-table-row-height)")
      zebra(true)
    end

    charts do
      chart_palette([:blue, :violet, :emerald])
    end
  end

  test "compiles theme metadata" do
    metadata = AdminTheme.__incant_theme__()

    assert metadata.module == AdminTheme
    assert metadata.css_vars_prefix == "--spell"
    assert metadata.palette == :zinc
    assert metadata.accent == :violet
    assert metadata.densities == [:compact, :comfortable]

    assert metadata.tokens == [
             {:color, :background, "var(--spell-background)"},
             {:radius, :md, "var(--spell-radius-md)"},
             {:spacing, :table_row_height, "var(--spell-table-row-height)"},
             {:font, :sans, "var(--spell-font-sans)"}
           ]

    assert metadata.table[:sticky_header]
    assert metadata.table[:row_height] == "var(--spell-table-row-height)"
    assert metadata.table[:zebra]
    assert metadata.charts == [palette: [:blue, :violet, :emerald]]
  end
end
