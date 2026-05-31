defmodule Incant.Table.Column do
  @moduledoc """
  Metadata for a resource table column.
  """

  @type t :: %__MODULE__{
          name: atom,
          opts: keyword
        }

  defstruct [:name, opts: []]
end
