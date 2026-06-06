defmodule Incant.UI.Focus do
  @moduledoc """
  Focus intent for adapters.

  Incant does not assign `tabindex` values. Adapters implement focus traps,
  roving tabindex, ARIA relationships, and focus restoration.
  """

  defstruct after_event: :none, target: nil
end
