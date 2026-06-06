defmodule Incant.UI.Actions.Action do
  @moduledoc """
  Semantic user-triggered command.
  """

  defstruct [:id, :label, :tone, :event, :confirm, :source]
end
