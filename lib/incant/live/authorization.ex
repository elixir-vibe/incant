defmodule Incant.Live.Authorization do
  @moduledoc false

  @actor_assigns [:current_scope, :current_user, :current_admin, :actor, :user]

  def actor(assigns, admin) do
    case admin.opts[:actor_assign] do
      nil -> first_present(assigns, @actor_assigns)
      assign_name -> Map.get(assigns, assign_name)
    end
  end

  def authorize(admin, action, actor, context) do
    case admin.opts[:policy] do
      nil -> :ok
      policy -> policy |> apply(:authorize, [action, actor, context]) |> normalize()
    end
  end

  def allowed?(admin, action, actor, context) do
    authorize(admin, action, actor, context) == :ok
  end

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
