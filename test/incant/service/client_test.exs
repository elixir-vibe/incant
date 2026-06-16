defmodule Incant.Service.ClientTest do
  use ExUnit.Case, async: true

  defmodule Repo do
    def all(_query), do: [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}]
    def one(_query), do: %{id: 1, name: "Ada"}
    def aggregate(_query, :count), do: 2
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

  test "client calls Incant service verbs without repeating SafeRPC operation tuples" do
    socket = socket_path("client")
    {:ok, server} = Server.start_link(socket: socket)

    client = Incant.Service.client(%{socket: socket, modules: [Admin]}, module: Admin)

    assert {:ok, %Incant.Admin.Contract{service: :accounts}} = Incant.Service.describe(client)

    assert {:ok, %{rows: [%{name: "Ada"}, %{name: "Grace"}]}} =
             Incant.Service.index(client, %Incant.Service.Index{surface_id: "user"})

    assert {:ok, %{id: 1, name: "Ada"}} =
             Incant.Service.read(client, %Incant.Service.Read{surface_id: "user", id: 1})

    GenServer.stop(server)
  end

  test "discover builds clients for modules exposing the Incant service shape" do
    socket = socket_path("discover")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{
      accounts: %{
        socket: socket,
        modules: [User, Admin]
      }
    }

    assert {:ok, [%Incant.Service.Client{module: Admin, endpoint: ^socket} = client]} =
             Incant.Service.discover(bindings)

    assert {:ok, %Incant.Admin.Contract{service: :accounts}} = Incant.Service.describe(client)

    GenServer.stop(server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-service-client-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
