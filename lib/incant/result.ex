defmodule Incant.Result do
  @moduledoc """
  Normalized result returned by Incant data sources.
  """

  @type t :: %__MODULE__{
          rows: [map | struct],
          columns: [atom],
          total_count: non_neg_integer | nil,
          meta: map
        }

  defstruct rows: [], columns: [], total_count: nil, meta: %{}
end
