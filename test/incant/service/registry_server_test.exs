defmodule Incant.Service.RegistryServerTest do
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

  test "starts with decoded bindings and exposes registry entries" do
    socket = socket_path("bindings")
    {:ok, rpc_server} = Server.start_link(socket: socket)

    bindings = %{accounts: %{socket: socket, modules: [Admin]}}
    {:ok, registry_server} = Incant.Service.RegistryServer.start_link(bindings: bindings)

    assert [%Incant.Service.Entry{key: :accounts, contract: contract}] =
             Incant.Service.RegistryServer.list_entries(registry_server)

    assert %Incant.Admin.Contract{service: :accounts} = contract

    assert %Incant.Service.Entry{client: %Incant.Service.Client{module: Admin}} =
             Incant.Service.RegistryServer.get_entry(registry_server, :accounts)

    assert %Incant.Service.Registry{bindings: ^bindings} =
             Incant.Service.RegistryServer.registry(registry_server)

    GenServer.stop(registry_server)
    GenServer.stop(rpc_server)
  end

  test "refresh reloads registry state" do
    first_socket = socket_path("refresh-first")
    second_socket = socket_path("refresh-second")
    {:ok, first_rpc} = Server.start_link(socket: first_socket)
    {:ok, second_rpc} = Server.start_link(socket: second_socket)

    path =
      Path.join(
        System.tmp_dir!(),
        "incant-registry-server-#{System.unique_integer([:positive])}.etf"
      )

    File.write!(
      path,
      :erlang.term_to_binary(%{accounts: %{socket: first_socket, modules: [Admin]}})
    )

    {:ok, registry_server} = Incant.Service.RegistryServer.start_link(path: path)

    assert [%Incant.Service.Entry{client: %Incant.Service.Client{endpoint: ^first_socket}}] =
             Incant.Service.RegistryServer.list_entries(registry_server)

    File.write!(
      path,
      :erlang.term_to_binary(%{accounts: %{socket: second_socket, modules: [Admin]}})
    )

    assert {:ok, %Incant.Service.Registry{entries: [entry]}} =
             Incant.Service.RegistryServer.refresh(registry_server)

    assert %Incant.Service.Entry{client: %Incant.Service.Client{endpoint: ^second_socket}} = entry

    File.rm(path)
    GenServer.stop(registry_server)
    GenServer.stop(first_rpc)
    GenServer.stop(second_rpc)
  end

  test "allow_empty starts without a binding file" do
    {:ok, registry_server} =
      Incant.Service.RegistryServer.start_link(path: "/missing/incant/rpc.etf", allow_empty: true)

    assert [] = Incant.Service.RegistryServer.list_entries(registry_server)
    assert {:error, :enoent} = Incant.Service.RegistryServer.refresh(registry_server)

    GenServer.stop(registry_server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-registry-server-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
