defmodule Incant.Admin.RPCTest do
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

  test "rpc: true makes the admin module an Incant service" do
    assert {:ok, %Incant.Admin.Contract{service: :accounts, version: "1"}} = Admin.describe(%{})
    assert {:ok, page} = Admin.index("user", %{}, %{})
    assert [%{id: 1, name: "Ada"}, %{id: 2, name: "Grace"}] = page.rows
    assert {:ok, %{id: 1, name: "Ada"}} = Admin.read("user", 1, %{})
  end

  test "rpc: true exposes Incant service functions through SafeRPC" do
    descriptor = Admin.__safe_rpc_descriptor__()

    assert %SafeRPC.Descriptor{service: :accounts, version: "1"} = descriptor

    assert %{incant_describe: describe, incant_index: index, incant_read: read} =
             descriptor.surfaces.control.ops

    assert describe.docs == "Describe this Incant admin surface."
    assert index.spec != nil
    assert read.spec != nil
  end

  test "rpc: true works over a SafeRPC socket" do
    socket = socket_path("admin")
    {:ok, server} = Server.start_link(socket: socket)

    assert {:ok, %Incant.Admin.Contract{service: :accounts}} =
             SafeRPC.call(socket, :incant_describe, %Incant.Service.Describe{})

    assert {:ok, %{rows: [%{name: "Ada"}, %{name: "Grace"}]}} =
             SafeRPC.call(socket, :incant_index, %Incant.Service.Index{surface_id: "user"})

    assert {:ok, %{id: 1, name: "Ada"}} =
             SafeRPC.call(socket, :incant_read, %Incant.Service.Read{surface_id: "user", id: 1})

    GenServer.stop(server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-admin-rpc-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
