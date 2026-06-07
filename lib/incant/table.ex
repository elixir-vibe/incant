defmodule Incant.Table do
  @moduledoc """
  Metadata for a resource table.
  """

  alias Incant.Table.{Action, Column, Filter}

  @type t :: %__MODULE__{
          columns: [Column.t()],
          filters: [Filter.t()],
          actions: [Action.t()],
          bulk_actions: [Action.t()],
          page_actions: [Action.t()],
          row_detail: keyword | nil,
          search: term,
          opts: keyword
        }

  defstruct columns: [],
            filters: [],
            actions: [],
            bulk_actions: [],
            page_actions: [],
            row_detail: nil,
            search: nil,
            opts: []
end
