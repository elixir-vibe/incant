defmodule Incant.Dashboard.Metadata do
  @moduledoc """
  Compiled metadata for an Incant dashboard.
  """

  alias Incant.Dashboard.{Variable, Widget}

  @type t :: %__MODULE__{
          module: module,
          title: String.t() | nil,
          variables: [Variable.t()],
          widgets: [Widget.t()],
          grid: keyword,
          opts: keyword
        }

  defstruct [:module, :title, variables: [], widgets: [], grid: [], opts: []]
end
