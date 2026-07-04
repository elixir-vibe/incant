defmodule Incant.Dashboard.Column do
  @moduledoc """
  Metadata for a dashboard table widget column.
  """

  @type t :: %__MODULE__{
          name: atom,
          opts: keyword
        }

  defstruct [:name, opts: []]
end
