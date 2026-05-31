defmodule Incant.Dashboard.Widget do
  @moduledoc """
  Metadata for a dashboard widget.
  """

  @type t :: %__MODULE__{
          id: atom,
          type: atom,
          opts: keyword
        }

  defstruct [:id, :type, opts: []]
end
