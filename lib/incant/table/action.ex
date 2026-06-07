defmodule Incant.Table.Action do
  @moduledoc """
  Metadata for a table action.

  Actions are semantic commands. A table can expose row actions, bulk actions,
  and page actions; adapters decide whether they render as buttons, menus,
  command palettes, drawers, or other UI primitives.
  """

  @type scope :: :row | :bulk | :page

  @type t :: %__MODULE__{
          name: atom,
          scope: scope,
          opts: keyword
        }

  defstruct [:name, scope: :row, opts: []]
end
