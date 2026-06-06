defmodule Incant.UI.Surfaces.Empty do
  @moduledoc """
  Empty or unauthorized admin surface.
  """

  defstruct [:id, :title, :context, regions: []]
end
