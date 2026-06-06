defmodule Incant.UI do
  @moduledoc """
  Semantic admin UI layer used by Incant render adapters.

  Incant core describes admin-domain surfaces, controls, actions, and events.
  Adapters decide markup, client behavior, accessibility implementation, and
  local draft state.
  """

  def render(document, %Incant.UI.Env{} = env) do
    env.adapter.render(document, env)
  end
end
