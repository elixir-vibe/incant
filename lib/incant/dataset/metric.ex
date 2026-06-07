defmodule Incant.Dataset.Metric do
  @moduledoc """
  Metadata for an analytical dataset metric.
  """

  @type aggregate :: atom | nil

  @type t :: %__MODULE__{
          name: atom,
          aggregate: aggregate,
          expr: term,
          opts: keyword
        }

  defstruct [:name, :aggregate, :expr, opts: []]
end
