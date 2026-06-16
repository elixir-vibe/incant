defmodule Incant.ControlPlaneTest do
  use ExUnit.Case, async: true

  defmodule Repo do
    def all(_query), do: [%{id: 1, name: "Ada"}]
    def one(_query), do: %{id: 1, name: "Ada"}
    def aggregate(_query, :count), do: 1
  end

  defmodule User do
    use Ecto.Schema

    schema "users" do
      field(:name, :string)
    end
  end

  defmodule Admin do
    use Incant.Admin, service: :accounts, version: "1", repo: Repo, rpc: true

    expose(User)
  end

  defmodule Server do
    use SafeRPC.Adapter.Server, service: Admin
  end

  test "central control-plane session payload feeds the same LiveView session provider" do
    socket = socket_path("control-plane")
    {:ok, rpc_server} = Server.start_link(socket: socket)
    bindings = %{accounts: %{socket: socket, modules: [Admin]}}

    {:ok, registry_server} = Incant.Service.RegistryServer.start_link(bindings: bindings)
    assert [entry] = Incant.ControlPlane.entries(registry_server)

    live_session = Incant.ControlPlane.live_session(entry, base_path: "/admin/services/accounts")
    session = Incant.Live.SessionProvider.fetch!(live_session)

    assert %Incant.Service.Session{} = session

    assert [%{id: "user", kind: :resource}] =
             Incant.Session.list_surfaces(session, kind: :resource)

    assert {:ok, %{rows: [%{name: "Ada"}]}} = Incant.Session.index(session, "user", %{}, %{}, [])

    GenServer.stop(registry_server)
    GenServer.stop(rpc_server)
  end

  test "children returns a registry server child spec tuple" do
    assert [{Incant.Service.RegistryServer, opts}] =
             Incant.ControlPlane.children(registry: [name: MyRegistry, allow_empty: true])

    assert opts[:name] == MyRegistry
    assert opts[:allow_empty]
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-control-plane-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
