defmodule Incant.Live.SessionProviderTest do
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

  test "builds local sessions from private LiveView session data" do
    phoenix_session = %{
      "__incant__" => %Incant.Live.Session{source: {:local, Admin}, base_path: "/admin"}
    }

    session = Incant.Live.SessionProvider.fetch!(phoenix_session, %{})

    assert %Incant.Session.Local{} = session

    assert %Incant.Admin.Metadata{module: Admin} =
             Incant.Live.SessionProvider.local_admin(phoenix_session)

    assert Incant.Live.SessionProvider.base_path(phoenix_session, %{}) == "/admin"
    assert %Incant.Admin.Contract{service: :accounts} = Incant.Session.contract(session)
  end

  test "builds service sessions from private entry data" do
    socket = socket_path("entry")
    {:ok, server} = Server.start_link(socket: socket)

    assert {:ok, %Incant.Service.Registry{entries: [entry]}} =
             Incant.Service.Registry.from_bindings(%{
               accounts: %{socket: socket, modules: [Admin]}
             })

    phoenix_session = %{"__incant__" => %Incant.Live.Session{source: {:entry, entry}}}
    session = Incant.Live.SessionProvider.fetch!(phoenix_session, %{})

    assert %Incant.Service.Session{} = session
    assert is_nil(Incant.Live.SessionProvider.local_admin(phoenix_session))
    assert [%{id: "user"}] = Incant.Session.list_surfaces(session, kind: :resource)

    GenServer.stop(server)
  end

  test "selects service sessions from a registry and route params" do
    socket = socket_path("registry")
    {:ok, server} = Server.start_link(socket: socket)
    bindings = %{accounts: %{socket: socket, modules: [Admin]}}
    {:ok, registry} = Incant.Service.RegistryServer.start_link(bindings: bindings)

    phoenix_session = %{
      "__incant__" => %Incant.Live.Session{source: {:registry, registry}, base_path: "/admin"}
    }

    session = Incant.Live.SessionProvider.fetch!(phoenix_session, %{"service" => "accounts"})

    assert %Incant.Service.Session{} = session

    assert Incant.Live.SessionProvider.base_path(phoenix_session, %{"service" => "accounts"}) ==
             "/admin/accounts"

    assert [%{id: "user"}] = Incant.Session.list_surfaces(session, kind: :resource)

    GenServer.stop(registry)
    GenServer.stop(server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-session-provider-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
