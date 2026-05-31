defmodule Incant.Table do
  @moduledoc """
  Metadata for a resource table.
  """

  alias Incant.Table.{Column, Filter}

  @type t :: %__MODULE__{
          columns: [Column.t()],
          filters: [Filter.t()],
          search: term,
          opts: keyword
        }

  defstruct columns: [], filters: [], search: nil, opts: []
end
