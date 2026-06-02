defmodule Incant.Live.Actions do
  @moduledoc false

  def run(resource, action_name, id, assigns) do
    with {:ok, action} <- fetch_action(resource, action_name),
         {:ok, row} <- fetch_row(resource, id) do
      params = %{action: action.name, id: id, row: row, resource: resource}
      dispatch(action, params, assigns)
    end
  end

  defp fetch_action(resource, action_name) do
    case Enum.find(resource.table.actions, &(to_string(&1.name) == action_name)) do
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
        {:error, "#{action.name} action for #{params.id} is not implemented yet"}

      callback ->
        normalize_result(Incant.Callback.call(callback, params, assigns), action, params)
    end
  end

  defp normalize_result(:ok, action, params),
    do: {:ok, "#{action.name} action completed for #{params.id}"}

  defp normalize_result({:ok, message}, _action, _params), do: {:ok, message}
  defp normalize_result({:error, message}, _action, _params), do: {:error, message}
  defp normalize_result(message, _action, _params) when is_binary(message), do: {:ok, message}

  defp normalize_result(_result, action, params),
    do: {:ok, "#{action.name} action completed for #{params.id}"}
end
