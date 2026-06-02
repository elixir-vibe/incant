defmodule Incant.Table do
  @moduledoc """
  Metadata for a resource table.
  """

  alias Incant.Table.{Action, Column, Filter}

  @type t :: %__MODULE__{
          columns: [Column.t()],
          filters: [Filter.t()],
          actions: [Action.t()],
          search: term,
          opts: keyword
        }

  defstruct columns: [], filters: [], actions: [], search: nil, opts: []
end
