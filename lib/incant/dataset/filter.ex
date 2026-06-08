defmodule Incant.Dataset.Filter do
  @moduledoc """
  Metadata for an analytical dataset filter.
  """

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          opts: keyword,
          query: term
        }

  defstruct [:name, :type, opts: [], query: nil]
end
