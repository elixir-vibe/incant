defmodule Incant.SessionTest do
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

  test "local and service sessions share the same protocol interface" do
    socket = socket_path("protocol")
    {:ok, server} = Server.start_link(socket: socket)

    local = Incant.Session.Local.new(Admin)

    {:ok, %Incant.Service.Registry{entries: [entry]}} =
      Incant.Service.Registry.from_bindings(%{accounts: %{socket: socket, modules: [Admin]}})

    remote = Incant.Service.Session.new(entry)

    for session <- [local, remote] do
      assert %Incant.Admin.Contract{service: :accounts} = Incant.Session.contract(session)

      assert [%{id: "user", kind: :resource}] =
               Incant.Session.list_surfaces(session, kind: :resource)

      assert {:ok, %{id: "user", kind: :resource}} =
               Incant.Session.fetch_surface(session, "user", [])

      assert {:ok, %{rows: rows}} = Incant.Session.index(session, "user", %{}, %{}, [])
      assert Enum.map(rows, &Incant.Live.Rows.field(&1, :name)) == ["Ada"]

      assert {:ok, row} = Incant.Session.read(session, "user", 1, %{}, [])
      assert Incant.Live.Rows.field(row, :name) == "Ada"
    end

    GenServer.stop(server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-session-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
