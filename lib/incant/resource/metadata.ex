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
          index: term,
          read: term,
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
    index: nil,
    read: nil,
    changeset: nil,
    form: %Form{},
    table: %Table{},
    opts: []
  ]
end
