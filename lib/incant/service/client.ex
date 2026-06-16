defmodule Incant.Service.Client do
  @moduledoc """
  Client-side handle for an Incant service exposed through SafeRPC.

  The client stores the SafeRPC endpoint and the discovered service module so
  callers can use Incant service verbs without repeating `{Module, function}`
  operation tuples at each call site.
  """

  @type endpoint :: Path.t() | pid() | atom()

  @type t :: %__MODULE__{
          endpoint: endpoint(),
          module: module(),
          binding: map() | nil,
          service: atom() | String.t() | nil,
          version: String.t() | nil,
          descriptor: SafeRPC.Descriptor.t() | nil
        }

  defstruct [:endpoint, :module, :binding, :service, :version, :descriptor]
end
