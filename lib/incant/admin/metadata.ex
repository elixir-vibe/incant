defmodule Incant.Admin.Metadata do
  @moduledoc """
  Compiled metadata for an Incant admin surface.
  """

  @type t :: %__MODULE__{
          module: module,
          resources: [module],
          exposed: [{module, keyword}],
          dashboards: [module],
          datasets: [module],
          plugins: [module],
          opts: keyword
        }

  defstruct [
    :module,
    resources: [],
    exposed: [],
    dashboards: [],
    datasets: [],
    plugins: [],
    opts: []
  ]
end
