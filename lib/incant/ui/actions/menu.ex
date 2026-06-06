defmodule Incant.UI.Actions.Menu do
  @moduledoc """
  Action menu model for adapters that render compact command surfaces.
  """

  defstruct [:id, :label, actions: []]
end
