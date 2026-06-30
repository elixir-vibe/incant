defmodule Incant.Web.API.ServiceResource do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  alias Incant.Service.Entry

  @derive Jason.Encoder
  defstruct [:service, :contract]

  @type t :: %__MODULE__{
          service: Incant.Web.API.ServiceSummary.t(),
          contract: Incant.Admin.Contract.t()
        }

  @spec from_entry(Entry.t()) :: t()
  def from_entry(%Entry{} = entry) do
    %__MODULE__{
      service: Incant.Web.API.ServiceSummary.from_entry(entry),
      contract: entry.contract
    }
  end
end
