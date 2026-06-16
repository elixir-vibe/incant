defmodule Incant.ControlPlane do
  @moduledoc """
  Helpers for central Incant admin/control-plane applications.

  A central app can supervise `Incant.Service.RegistryServer`, list entries, and
  pass one entry into `Incant.Live.Admin` as ordinary LiveView session data.
  The LiveView then renders through the unified `Incant.Session` protocol.
  """

  alias Incant.Service.Entry
  alias Incant.Service.RegistryServer

  @doc "Returns child specs needed for a minimal central Incant control plane."
  @spec children(keyword()) :: [Supervisor.child_spec() | {module(), term()}]
  def children(opts \\ []) do
    registry_opts = Keyword.get(opts, :registry, [])
    name = Keyword.get(registry_opts, :name, Incant.Service.RegistryServer)
    [{RegistryServer, Keyword.put_new(registry_opts, :name, name)}]
  end

  @doc "Builds LiveView session data for a discovered service entry."
  @spec live_session(Entry.t(), keyword()) :: map()
  def live_session(%Entry{} = entry, opts \\ []) do
    %{
      "incant_entry" => entry,
      "base_path" => Keyword.get(opts, :base_path, "/admin")
    }
  end

  @doc "Lists discovered entries from a registry server."
  @spec entries(RegistryServer.server()) :: [Entry.t()]
  def entries(server \\ RegistryServer), do: RegistryServer.list_entries(server)
end
