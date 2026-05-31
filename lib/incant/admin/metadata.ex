defmodule Incant.Admin.Metadata do
  @moduledoc """
  Compiled metadata for an Incant admin surface.
  """

  @type t :: %__MODULE__{
          module: module,
          resources: [module],
          dashboards: [module],
          plugins: [module],
          opts: keyword
        }

  defstruct [:module, resources: [], dashboards: [], plugins: [], opts: []]
end
