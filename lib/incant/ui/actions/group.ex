defmodule Incant.UI.Actions.Group do
  @moduledoc """
  Group of related UI actions.
  """

  defstruct [:id, :label, actions: []]
end
