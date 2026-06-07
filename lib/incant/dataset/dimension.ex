defmodule Incant.Dataset.Dimension do
  @moduledoc """
  Metadata for an analytical dataset dimension.
  """

  @type t :: %__MODULE__{name: atom, opts: keyword}

  defstruct [:name, opts: []]
end
