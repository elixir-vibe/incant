defmodule Incant.Form.Field do
  @moduledoc """
  Metadata for a resource form field.
  """

  @type t :: %__MODULE__{
          name: atom,
          type: atom,
          opts: keyword
        }

  defstruct [:name, type: :auto, opts: []]
end
