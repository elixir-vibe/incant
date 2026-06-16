defmodule Incant.Service.Entry do
  @moduledoc """
  A discovered Incant service endpoint and its loaded admin contract.

  Central control-plane processes can keep entries in memory and route UI
  events back through `client` while rendering from `contract`.
  """

  @type binding_key :: atom() | String.t() | nil

  @type t :: %__MODULE__{
          key: binding_key(),
          client: Incant.Service.Client.t(),
          contract: Incant.Admin.Contract.t(),
          binding: SafeRPC.local_binding() | nil
        }

  defstruct [:key, :client, :contract, :binding]
end
