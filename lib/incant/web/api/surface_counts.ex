defmodule Incant.Web.API.SurfaceCounts do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive Jason.Encoder
  defstruct resources: 0, dashboards: 0, datasets: 0

  @type t :: %__MODULE__{
          resources: non_neg_integer(),
          dashboards: non_neg_integer(),
          datasets: non_neg_integer()
        }

  @spec from_contract(Incant.Admin.Contract.t()) :: t()
  def from_contract(contract) do
    %__MODULE__{
      resources: length(contract.resources),
      dashboards: length(contract.dashboards),
      datasets: length(contract.datasets)
    }
  end
end
