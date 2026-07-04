defmodule Incant.Service.ContractMaterializer do
  @moduledoc false

  alias Incant.Dashboard.Widget
  alias Incant.Table.Column

  def surface(surface) do
    case get(surface, :kind) do
      :dashboard -> dashboard_surface(surface)
      "dashboard" -> dashboard_surface(surface)
      _other -> surface
    end
  end

  defp dashboard_surface(surface) do
    update(surface, :widgets, fn widgets -> Enum.map(widgets || [], &widget/1) end)
  end

  defp widget(widget) do
    %Widget{
      id: get(widget, :id),
      type: type(get(widget, :type)),
      opts: widget_opts(get(widget, :opts) || %{})
    }
  end

  defp widget_opts(opts) do
    opts
    |> keywordize()
    |> Keyword.update(:columns, [], &Enum.map(&1, fn column -> column(column) end))
  end

  defp column(%Column{} = column), do: column

  defp column(column) do
    %Column{
      name: get(column, :name) || get(column, :id),
      opts: keywordize(get(column, :opts) || %{})
    }
  end

  defp type(type) when is_binary(type), do: String.to_existing_atom(type)
  defp type(type), do: type

  defp keywordize(options) when is_list(options), do: options

  defp keywordize(options) when is_map(options) do
    Enum.map(options, fn {key, value} -> {key(key), value} end)
  end

  defp keywordize(_options), do: []

  defp key(key) when is_atom(key), do: key
  defp key(key) when is_binary(key), do: String.to_existing_atom(key)

  defp get(map, key) when is_map(map), do: Map.get(map, key) || Map.get(map, to_string(key))
  defp get(_map, _key), do: nil

  defp update(map, key, fun) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.update!(map, key, fun)
      Map.has_key?(map, to_string(key)) -> Map.update!(map, to_string(key), fun)
      true -> map
    end
  end
end
