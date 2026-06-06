defmodule Incant.UI.Adapter do
  @moduledoc """
  Behaviour for Incant UI render adapters.

  Adapters render semantic Incant UI nodes. They may delegate unsupported nodes
  to another adapter instead of advertising a global capability list.
  """

  @callback render(node :: struct, env :: Incant.UI.Env.t()) :: Phoenix.LiveView.Rendered.t()
end
