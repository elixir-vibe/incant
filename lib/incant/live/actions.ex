defmodule Incant.Live.Actions do
  @moduledoc false

  alias Incant.ActionResult

  def run(resource, action_name, id, assigns, context \\ %{}) do
    with {:ok, action} <- fetch_action(resource.table.actions, action_name),
         {:ok, row} <- fetch_row(resource, id, context),
         :ok <- available(action, row, context),
         :ok <- authorize(context, :run_action, action, %{id: id, row: row}) do
      params = %{action: action.name, id: id, row: row, resource: resource}
      dispatch(action, params, assigns)
    end
  end

  def run_bulk(resource, action_name, selected_ids, assigns, context \\ %{}) do
    with {:ok, action} <- fetch_action(resource.table.bulk_actions, action_name),
         :ok <- authorize(context, :run_bulk_action, action, %{selected_ids: selected_ids}) do
      rows =
        Enum.map(selected_ids, &Incant.Live.Rows.one(resource, &1, context))
        |> Enum.reject(&is_nil/1)

      params = %{action: action.name, selected_ids: selected_ids, rows: rows, resource: resource}
      dispatch(action, params, assigns)
    end
  end

  def run_page(resource, action_name, assigns, context \\ %{}) do
    with {:ok, action} <- fetch_action(resource.table.page_actions, action_name),
         :ok <- authorize(context, :run_page_action, action, %{}) do
      params = %{action: action.name, resource: resource}
      dispatch(action, params, assigns)
    end
  end

  defp fetch_action(actions, action_name) do
    case Enum.find(actions, &(to_string(&1.name) == action_name)) do
      nil -> {:error, "Unknown action #{action_name}"}
      action -> {:ok, action}
    end
  end

  defp fetch_row(resource, id, context) do
    case Incant.Live.Rows.one(resource, id, context) do
      nil -> {:error, "No row matches #{id}"}
      row -> {:ok, row}
    end
  end

  defp available(action, row, context) do
    if Incant.Table.Action.available?(action, row, context),
      do: :ok,
      else: {:error, "Action #{action.name} is not available for this row"}
  end

  defp authorize(%{admin: admin, actor: actor} = context, action_name, action, extra) do
    Incant.Live.Authorization.authorize(
      admin,
      action_name,
      actor,
      context
      |> context_map()
      |> Map.merge(%{resource: context.resource, action: action})
      |> Map.merge(extra)
    )
  end

  defp authorize(_context, _action_name, _action, _extra), do: :ok

  defp context_map(%_struct{} = context), do: Map.from_struct(context)
  defp context_map(context) when is_map(context), do: context

  defp dispatch(action, params, assigns) do
    case action.opts[:callback] do
      nil ->
        ActionResult.error("#{action.name} action is not implemented yet")

      callback ->
        callback
        |> Incant.Callback.call(params, assigns)
        |> ActionResult.normalize(action: action, params: params)
    end
  end
end
