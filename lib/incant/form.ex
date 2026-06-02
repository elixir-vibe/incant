defmodule Incant.Form do
  @moduledoc """
  Metadata for resource create/edit forms.
  """

  alias Incant.Form.Field

  @type t :: %__MODULE__{
          fields: [Field.t()],
          opts: keyword
        }

  defstruct fields: [], opts: []
end
