defmodule Incant.Dataset.Table do
  @moduledoc """
  Metadata for the default table view of an analytical dataset.
  """

  alias Incant.Dataset.Drilldown

  @type t :: %__MODULE__{
          group_by: [atom],
          columns: [atom],
          sort: {atom, :asc | :desc} | nil,
          heatmap: [atom],
          drilldowns: [Drilldown.t()],
          opts: keyword
        }

  defstruct group_by: [], columns: [], sort: nil, heatmap: [], drilldowns: [], opts: []
end
