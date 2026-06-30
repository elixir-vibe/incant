defmodule Incant.Admin.Contract do
  @moduledoc """
  Transport-safe description of an Incant admin surface.

  Contracts are intended for discovery, SafeRPC responses, audits, and remote UI
  clients. They contain stable data only; local callbacks, repos, schemas, and
  other executable BEAM terms remain in regular Incant metadata and executors.
  """

  @type surface :: map()

  @type t :: %__MODULE__{
          id: String.t(),
          module: String.t(),
          service: atom | String.t() | nil,
          version: String.t() | nil,
          resources: [surface()],
          dashboards: [surface()],
          datasets: [surface()],
          plugins: [String.t()],
          opts: map()
        }

  @derive {Jason.Encoder,
           only: [
             :id,
             :module,
             :service,
             :version,
             :resources,
             :dashboards,
             :datasets,
             :plugins,
             :opts
           ]}
  defstruct [
    :id,
    :module,
    :service,
    :version,
    resources: [],
    dashboards: [],
    datasets: [],
    plugins: [],
    opts: %{}
  ]
end
