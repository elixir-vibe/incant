defmodule Incant.Resource.Metadata do
  @moduledoc """
  Compiled metadata for an Incant resource.
  """

  alias Incant.Table

  @type t :: %__MODULE__{
          module: module,
          schema: module | nil,
          repo: module | nil,
          query: term,
          data: term,
          table: Table.t(),
          opts: keyword
        }

  defstruct [:module, :schema, :repo, query: nil, data: nil, table: %Table{}, opts: []]
end
