defmodule Incant.Web.API.ActionRunRequest do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  defstruct payload: %Incant.Web.API.ActionPayload{}, context: %{}

  @type t :: %__MODULE__{payload: Incant.Web.API.ActionPayload.t(), context: map()}

  @spec cast(map()) :: {:ok, t()} | {:error, {:invalid_request, Exception.t()}}
  def cast(params), do: Incant.Web.API.JSON.cast(__MODULE__, params)
end
