defmodule Incant.UI.Document do
  @moduledoc """
  A semantic description of the current Incant admin screen.
  """

  alias Incant.UI.Regions.Nav
  alias Incant.UI.Surfaces.{Dashboard, ResourceIndex}

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          surface: struct,
          nav: Nav.t() | nil,
          regions: [struct],
          events: map,
          meta: map,
          context: map | nil
        }

  defstruct [:id, :title, :surface, :nav, regions: [], events: %{}, meta: %{}, context: nil]

  def from_context(context, opts \\ []) do
    title = Keyword.get(opts, :title) || Keyword.get(opts, :page_title) || surface_title(context)
    surface = surface_from_context(context, title)

    %__MODULE__{
      id: document_id(context),
      title: title,
      surface: surface,
      nav: Nav.from_context(context),
      regions: surface_regions(surface),
      events: %{},
      meta: %{},
      context: context
    }
  end

  defp surface_from_context(%{section: "dashboard", dashboard: dashboard} = context, title)
       when not is_nil(dashboard) do
    Dashboard.from_context(context, title)
  end

  defp surface_from_context(%{section: "resource", resource: resource} = context, title)
       when not is_nil(resource) do
    ResourceIndex.from_context(context, title)
  end

  defp surface_from_context(context, title) do
    %Incant.UI.Surfaces.Empty{id: "empty", title: title, context: context}
  end

  defp surface_regions(%{regions: regions}), do: regions

  defp document_id(%{section: section}) when is_binary(section), do: section
  defp document_id(_context), do: "admin"

  defp surface_title(%{resource: %{module: module}}) when not is_nil(module),
    do: short_module(module)

  defp surface_title(%{dashboard: %{title: title}}) when is_binary(title), do: title
  defp surface_title(_context), do: "Admin"

  defp short_module(module), do: module |> Module.split() |> List.last()
end
