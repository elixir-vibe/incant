defmodule Incant.UI.Adapters.LiveView.RecipeTest do
  use ExUnit.Case, async: true

  alias Incant.UI.Adapters.LiveView.Recipe
  alias Incant.UI.Adapters.LiveView.Recipe.CompoundVariant

  test "resolves slots, variants, compound variants, and defaults" do
    recipe = %Recipe{
      slots: %{base: "base", label: "label"},
      variants: %{
        active: %{
          true => %{base: "active-base"},
          false => %{base: "inactive-base"}
        },
        size: %{
          sm: %{base: "small", label: "small-label"},
          md: %{base: "medium"}
        }
      },
      compound_variants: [
        %CompoundVariant{match: %{active: true, size: :sm}, classes: %{base: "active-small"}}
      ],
      default_variants: %{active: false, size: :md}
    }

    assert Recipe.slot(recipe, :base) == ["base", ["inactive-base", "medium"], []]

    assert Recipe.slot(recipe, :base, active: true, size: :sm) == [
             "base",
             ["active-base", "small"],
             ["active-small"]
           ]

    assert Recipe.slot(recipe, :label, size: :sm) == ["label", [nil, "small-label"], []]
  end
end
