defmodule Incant.Web.API.ActionRunRequest do
  @moduledoc """
  Typed request contract for running Incant actions over the standalone HTTP API.

  Carries the decoded action payload plus caller context. Library/embedded
  consumers do not interact with this module.
  """

  use JSONCodec, fast_path: :json, strict: true

  defstruct payload: %Incant.Web.API.ActionPayload{}, context: %{}

  codec(:payload, cast: :cast_payload)

  @type t :: %__MODULE__{payload: Incant.Web.API.ActionPayload.t(), context: map()}

  @spec cast(map()) :: {:ok, t()} | {:error, {:invalid_request, Exception.t()}}
  def cast(params), do: Incant.Web.API.JSON.cast(__MODULE__, params)

  def cast_payload(%Incant.Web.API.ActionPayload{} = payload), do: payload

  def cast_payload(payload) when is_map(payload),
    do: Incant.Web.API.ActionPayload.from_map!(payload)

  def cast_payload(payload), do: payload
end
