defmodule Incant.Live.Authorization do
  @moduledoc false

  @actor_assigns [:current_scope, :current_user, :current_admin, :actor, :user]

  def actor(assigns, admin) do
    cond do
      actor = admin.opts[:actor] -> actor_from_callback(actor, assigns)
      assign_name = admin.opts[:actor_assign] -> Map.get(assigns, assign_name)
      true -> first_present(assigns, @actor_assigns)
    end
  end

  def authorize(admin, action, actor, context) do
    case policy(admin, action, context) do
      nil -> :ok
      policy -> policy |> apply(:authorize, [action, actor, context]) |> normalize()
    end
  end

  def allowed?(admin, action, actor, context) do
    authorize(admin, action, actor, context) == :ok
  end

  def policy(admin, action, context) do
    local_policy(action, context) || admin.opts[:policy]
  end

  defp local_policy(:view_dashboard, %{dashboard: %{opts: opts}}), do: opts[:policy]

  defp local_policy(action, %{resource: %{opts: opts}})
       when action in [:view_resource, :view_row, :create, :edit, :run_action],
       do: opts[:policy]

  defp local_policy(_action, _context), do: nil

  defp actor_from_callback({module, function}, assigns), do: apply(module, function, [assigns])

  defp actor_from_callback(function, assigns) when is_function(function, 1),
    do: function.(assigns)

  defp actor_from_callback(_callback, _assigns), do: nil

  defp first_present(assigns, [assign | rest]) do
    case Map.fetch(assigns, assign) do
      {:ok, value} -> value
      :error -> first_present(assigns, rest)
    end
  end

  defp first_present(_assigns, []), do: nil

  defp normalize(result) when result in [true, :ok], do: :ok
  defp normalize({:error, reason}), do: {:error, reason}
  defp normalize(result) when result in [false, :error], do: {:error, :unauthorized}
  defp normalize(_result), do: {:error, :unauthorized}
end
