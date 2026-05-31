defmodule Incant.Dashboard.Variable do
  @moduledoc """
  Metadata for a dashboard variable.
  """

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          opts: keyword
        }

  defstruct [:name, :type, opts: []]
end
