defmodule Incant.Dataset.Drilldown do
  @moduledoc """
  Metadata for a table drilldown path in an analytical dataset.
  """

  @type t :: %__MODULE__{dimension: atom, opts: keyword}

  defstruct [:dimension, opts: []]
end
