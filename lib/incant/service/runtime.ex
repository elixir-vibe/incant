defmodule Incant.Service.Runtime do
  @moduledoc false

  alias Incant.{ActionResult, Live}

  def describe(admin, _context \\ %{}) do
    {:ok, Incant.Admin.describe(admin)}
  end

  def index(admin, surface_id, params \\ %{}, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind do
      table = Map.get(params, :table, params)
      {:ok, Live.Rows.page(surface.spec, table, service_context(admin, surface, context))}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def read(admin, surface_id, id, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind do
      case Live.Rows.one(surface.spec, id, service_context(admin, surface, context)) do
        nil -> {:error, :not_found}
        row -> {:ok, row}
      end
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def run_action(admin, surface_id, action_id, payload \\ %{}, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind do
      assigns = Map.get(payload, :assigns, %{})
      id = Map.get(payload, :id)
      selected_ids = Map.get(payload, :selected_ids)
      action_context = service_context(admin, surface, context)

      result =
        cond do
          not is_nil(id) ->
            Live.Actions.run(surface.spec, to_string(action_id), id, assigns, action_context)

          is_list(selected_ids) ->
            Live.Actions.run_bulk(
              surface.spec,
              to_string(action_id),
              selected_ids,
              assigns,
              action_context
            )

          true ->
            Live.Actions.run_page(surface.spec, to_string(action_id), assigns, action_context)
        end

      {:ok, ActionResult.normalize(result)}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  defp fetch_surface(admin, surface_id) do
    admin
    |> Incant.Admin.surfaces()
    |> Enum.find(&(to_string(&1.id) == to_string(surface_id)))
    |> case do
      nil -> {:error, {:unknown_surface, surface_id}}
      surface -> {:ok, surface}
    end
  end

  defp service_context(admin, surface, context) do
    context
    |> context_map()
    |> Map.put_new(:admin, admin)
    |> Map.put_new(:surface, surface)
    |> Map.put_new(:resource, surface.spec)
  end

  defp context_map(%_struct{} = context), do: Map.from_struct(context)
  defp context_map(context) when is_map(context), do: context
  defp context_map(_context), do: %{}
end
