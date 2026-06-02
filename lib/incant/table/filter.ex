defmodule Incant.Table.Filter do
  @moduledoc """
  Metadata for a resource table filter.
  """

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          opts: keyword,
          query: term
        }

  defstruct [:name, :type, opts: [], query: nil]
end
