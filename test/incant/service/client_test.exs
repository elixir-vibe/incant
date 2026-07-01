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

    assert {:ok, %{"rows" => [%{"id" => "1", "cells" => ada_cells}, %{"id" => "2"}]}} =
             Incant.Service.index(client, %Incant.Service.Index{surface_id: "user"})

    assert %{"column" => "name", "value" => "Ada"} in ada_cells

    assert {:ok, %{"id" => "1", "cells" => read_cells}} =
             Incant.Service.read(client, %Incant.Service.Read{surface_id: "user", id: 1})

    assert %{"column" => "name", "value" => "Ada"} in read_cells

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

  test "discover prepares service atoms with caller policy" do
    socket = socket_path("discover-atoms-policy")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{accounts: %{socket: socket, modules: [Admin]}}

    assert {:ok, [%Incant.Service.Client{module: Admin}]} =
             Incant.Service.discover(bindings,
               atoms: [
                 max_atoms: 100,
                 max_atom_length: 128,
                 allow: [~r/^[a-z][a-z0-9_]*$/, ~r/^[A-Za-z][A-Za-z0-9_.]*$/]
               ]
             )

    GenServer.stop(server)
  end

  test "discover returns atom preparation errors" do
    socket = socket_path("discover-atoms-error")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{accounts: %{socket: socket, modules: [Admin]}}

    assert {:error, {:too_many_atoms, count, 1}} =
             Incant.Service.discover(bindings, atoms: [max_atoms: 1])

    assert count > 1

    GenServer.stop(server)
  end

  test "discover returns probe errors when no module exposes Incant service" do
    socket = socket_path("discover-none")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{accounts: %{socket: socket, modules: [User]}}

    assert {:error, {:no_incant_service, [{User, :unknown_operation}]}} =
             Incant.Service.discover(bindings)

    GenServer.stop(server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-service-client-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
