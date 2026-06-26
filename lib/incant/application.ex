defmodule Incant.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    Supervisor.start_link(children(), strategy: :one_for_one, name: Incant.Supervisor)
  end

  def children do
    if Application.get_env(:incant, :serve?, false) do
      [
        registry_child(),
        Incant.Web.Endpoint
      ]
    else
      []
    end
  end

  defp registry_child do
    opts = Application.get_env(:incant, :registry, env: "HOSTKIT_RPC_BINDINGS")

    {Incant.Service.RegistryServer, Keyword.put_new(opts, :name, Incant.Service.RegistryServer)}
  end
end
