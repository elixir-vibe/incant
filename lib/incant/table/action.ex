defmodule Incant.Table.Action do
  @moduledoc """
  Metadata for a resource row action.
  """

  @type t :: %__MODULE__{
          name: atom,
          opts: keyword
        }

  defstruct [:name, opts: []]
end
