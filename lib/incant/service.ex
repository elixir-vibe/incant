defmodule Incant.Service do
  @moduledoc """
  Behaviour for service-owned Incant admin/control-plane surfaces.

  `use Incant.Admin, rpc: true` implements this behaviour and exposes it through
  SafeRPC. Application modules should usually use the Incant admin DSL instead
  of implementing this behaviour by hand.
  """

  @callback describe(context :: map()) :: {:ok, Incant.Admin.Contract.t()} | {:error, term()}
  @callback index(surface_id :: String.t(), params :: map(), context :: map()) ::
              {:ok, map()} | {:error, term()}
  @callback read(surface_id :: String.t(), id :: term(), context :: map()) ::
              {:ok, term()} | {:error, term()}
  @callback run_action(
              surface_id :: String.t(),
              action_id :: String.t(),
              payload :: map(),
              context :: map()
            ) :: {:ok, Incant.ActionResult.t()} | {:error, term()}
end
