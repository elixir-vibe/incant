defmodule Incant.Resource.Metadata do
  @moduledoc """
  Compiled metadata for an Incant resource.
  """

  alias Incant.{Form, Table}

  @type t :: %__MODULE__{
          id: String.t(),
          module: module,
          schema: module | nil,
          repo: module | nil,
          query: term,
          data: term,
          changeset: term,
          form: Form.t(),
          table: Table.t(),
          opts: keyword
        }

  defstruct [
    :id,
    :module,
    :schema,
    :repo,
    query: nil,
    data: nil,
    changeset: nil,
    form: %Form{},
    table: %Table{},
    opts: []
  ]
end
