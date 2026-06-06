defmodule Incant.UI.Adapters.LiveView.Recipe do
  @moduledoc false

  defmodule CompoundVariant do
    @moduledoc false
    @enforce_keys [:match, :classes]
    defstruct [:match, :classes]
  end

  @enforce_keys [:slots]
  defstruct slots: %{}, variants: %{}, compound_variants: [], default_variants: %{}

  def slot(%__MODULE__{} = recipe, slot, opts \\ []) do
    opts =
      opts
      |> Map.new()
      |> Map.merge(recipe.default_variants, fn _key, value, _default -> value end)

    [
      Map.fetch!(recipe.slots, slot),
      variant_classes(recipe, slot, opts),
      compound_classes(recipe, slot, opts)
    ]
  end

  defp variant_classes(recipe, slot, opts) do
    Enum.map(recipe.variants, fn {name, values} ->
      value = Map.get(opts, name)
      values |> Map.get(value, %{}) |> Map.get(slot)
    end)
  end

  defp compound_classes(recipe, slot, opts) do
    recipe.compound_variants
    |> Enum.filter(&compound_match?(&1, opts))
    |> Enum.map(&Map.get(&1.classes, slot))
  end

  defp compound_match?(%CompoundVariant{match: match}, opts) do
    Enum.all?(match, fn {name, expected} -> Map.get(opts, name) == expected end)
  end
end
