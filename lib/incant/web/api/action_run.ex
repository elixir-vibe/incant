defmodule Incant.Web.API.ActionRun do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive Jason.Encoder
  defstruct [:type, :status, :result]

  @type t :: %__MODULE__{
          type: atom(),
          status: atom(),
          result: Incant.Web.API.ActionResult.t()
        }

  codec(:type, atom: {:enum, [:action_run]})
  codec(:status, atom: {:enum, [:succeeded]})

  @spec succeeded(Incant.ActionResult.t()) :: t()
  def succeeded(result) do
    %__MODULE__{
      type: :action_run,
      status: :succeeded,
      result: Incant.Web.API.ActionResult.from_incant(result)
    }
  end
end
