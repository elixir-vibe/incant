defmodule Incant.Live.Actions do
  @moduledoc false

  alias Incant.ActionResult

  def run(resource, action_name, id, assigns) do
    with {:ok, action} <- fetch_action(resource.table.actions, action_name),
         {:ok, row} <- fetch_row(resource, id) do
      params = %{action: action.name, id: id, row: row, resource: resource}
      dispatch(action, params, assigns)
    end
  end

  def run_bulk(resource, action_name, selected_ids, assigns) do
    with {:ok, action} <- fetch_action(resource.table.bulk_actions, action_name) do
      rows = Enum.map(selected_ids, &Incant.Live.Rows.one(resource, &1)) |> Enum.reject(&is_nil/1)
      params = %{action: action.name, selected_ids: selected_ids, rows: rows, resource: resource}
      dispatch(action, params, assigns)
    end
  end

  def run_page(resource, action_name, assigns) do
    with {:ok, action} <- fetch_action(resource.table.page_actions, action_name) do
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

  defp fetch_row(resource, id) do
    case Incant.Live.Rows.one(resource, id) do
      nil -> {:error, "No row matches #{id}"}
      row -> {:ok, row}
    end
  end

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
