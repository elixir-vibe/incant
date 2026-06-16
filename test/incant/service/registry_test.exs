defmodule Incant.Service.RegistryTest do
  use ExUnit.Case, async: false

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

  test "from_bindings discovers services and loads contracts" do
    socket = socket_path("bindings")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{
      accounts: %{
        socket: socket,
        modules: [Admin]
      }
    }

    assert {:ok, %Incant.Service.Registry{entries: [entry], bindings: ^bindings}} =
             Incant.Service.Registry.from_bindings(bindings)

    assert %Incant.Service.Entry{
             key: :accounts,
             client: %Incant.Service.Client{module: Admin, endpoint: ^socket},
             contract: %Incant.Admin.Contract{service: :accounts, version: "1"}
           } = entry

    GenServer.stop(server)
  end

  test "load_file decodes HostKit binding ETF and discovers contracts" do
    socket = socket_path("file")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{
      "accounts" => %{
        socket: socket,
        modules: [Admin]
      }
    }

    path =
      Path.join(System.tmp_dir!(), "incant-registry-#{System.unique_integer([:positive])}.etf")

    File.write!(path, :erlang.term_to_binary(bindings))

    assert {:ok, %Incant.Service.Registry{source: {:file, ^path}, entries: [entry]}} =
             Incant.Service.Registry.load_file(path)

    assert %Incant.Service.Entry{key: "accounts", contract: %Incant.Admin.Contract{}} = entry

    File.rm(path)
    GenServer.stop(server)
  end

  test "load reads binding path from HOSTKIT_RPC_BINDINGS by default" do
    socket = socket_path("env")
    {:ok, server} = Server.start_link(socket: socket)

    bindings = %{accounts: %{socket: socket, modules: [Admin]}}

    path =
      Path.join(
        System.tmp_dir!(),
        "incant-registry-env-#{System.unique_integer([:positive])}.etf"
      )

    File.write!(path, :erlang.term_to_binary(bindings))

    previous = System.get_env("HOSTKIT_RPC_BINDINGS")
    System.put_env("HOSTKIT_RPC_BINDINGS", path)

    try do
      assert {:ok,
              %Incant.Service.Registry{
                source: {:env, "HOSTKIT_RPC_BINDINGS", ^path},
                entries: [%Incant.Service.Entry{key: :accounts}]
              }} = Incant.Service.Registry.load()
    after
      restore_env("HOSTKIT_RPC_BINDINGS", previous)
      File.rm(path)
      GenServer.stop(server)
    end
  end

  test "decode_bindings rejects invalid ETF" do
    assert {:error, %ArgumentError{}} = Incant.Service.Registry.decode_bindings("not etf")
  end

  defp restore_env(name, nil), do: System.delete_env(name)
  defp restore_env(name, value), do: System.put_env(name, value)

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-service-registry-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
