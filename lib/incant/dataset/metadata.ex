defmodule Incant.Dataset.Metadata do
  @moduledoc """
  Compiled metadata for an Incant analytical dataset.
  """

  alias Incant.Dataset.{Dimension, Filter, Metric, Table}

  @type t :: %__MODULE__{
          module: module,
          source: module | term,
          title: String.t() | nil,
          from: term,
          dimensions: [Dimension.t()],
          metrics: [Metric.t()],
          filters: [Filter.t()],
          table: Table.t(),
          opts: keyword
        }

  defstruct [
    :module,
    :source,
    :title,
    :from,
    dimensions: [],
    metrics: [],
    filters: [],
    table: %Table{},
    opts: []
  ]
end
