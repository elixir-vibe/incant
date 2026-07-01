defmodule Incant.Web.APITest do
  use ExUnit.Case, async: true
  import Plug.Conn
  import Plug.Test

  alias Incant.ActionResult

  @opts Incant.Web.API.init([])
  @media_type "application/vnd.incant.admin+json"

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

  defmodule UserResource do
    use Incant.Resource, schema: User, repo: Repo

    table do
      column(:name)

      actions do
        page(:sync, callback: &__MODULE__.sync/2)
      end
    end

    def sync(_params, assigns) do
      ActionResult.job("sync", label: assigns["label"] || "Sync")
    end
  end

  defmodule Admin do
    use Incant.Admin, service: :accounts, version: "1", rpc: true

    resource(UserResource)
  end

  defmodule Server do
    use SafeRPC.Adapter.Server, service: Admin
  end

  setup do
    socket = socket_path()
    {:ok, server} = Server.start_link(socket: socket)

    {:ok, registry} =
      Incant.Service.RegistryServer.start_link(
        bindings: %{accounts: %{socket: socket, modules: [Admin]}}
      )

    on_exit(fn ->
      if Process.alive?(registry), do: GenServer.stop(registry)
      if Process.alive?(server), do: GenServer.stop(server)
    end)

    %{registry: registry}
  end

  test "lists discovered services", %{registry: registry} do
    conn = call_api(conn(:get, "/services"), registry)

    assert conn.status == 200
    assert content_type(conn) == @media_type
    assert get_resp_header(conn, "cache-control") == ["no-store"]
    assert get_resp_header(conn, "vary") == ["accept"]

    assert %{
             "data" => [
               %{
                 "id" => "accounts",
                 "service" => "accounts",
                 "version" => "1",
                 "surfaces" => %{"resources" => 1}
               }
             ],
             "links" => %{"self" => "/services"}
           } = Jason.decode!(conn.resp_body)
  end

  test "filters surfaces by kind", %{registry: registry} do
    conn = call_api(conn(:get, "/services/accounts/surfaces?kind=resource"), registry)

    assert conn.status == 200

    assert %{"data" => [%{"id" => "user_resource", "kind" => "resource"}]} =
             Jason.decode!(conn.resp_body)
  end

  test "returns a service contract", %{registry: registry} do
    conn = call_api(conn(:get, "/services/accounts"), registry)

    assert conn.status == 200

    assert %{
             "data" => %{
               "service" => %{"id" => "accounts"},
               "contract" => %{"resources" => [%{"id" => "user_resource"}]}
             },
             "links" => %{"surfaces" => "/incant/services/accounts/surfaces"}
           } = Jason.decode!(conn.resp_body)
  end

  test "queries resource surfaces", %{registry: registry} do
    conn =
      :post
      |> json_conn("/services/accounts/surfaces/user_resource/queries", %{"table" => %{}})
      |> call_api(registry)

    assert conn.status == 200

    assert %{
             "data" => %{
               "rows" => [
                 %{"id" => "1", "cells" => [%{"column" => "name", "value" => "Ada"}]},
                 %{"id" => "2", "cells" => [%{"column" => "name", "value" => "Grace"}]}
               ]
             }
           } = Jason.decode!(conn.resp_body)
  end

  test "reads resource rows", %{registry: registry} do
    conn = call_api(conn(:get, "/services/accounts/surfaces/user_resource/rows/1"), registry)

    assert conn.status == 200

    assert %{"data" => %{"id" => "1", "cells" => [%{"column" => "name", "value" => "Ada"}]}} =
             Jason.decode!(conn.resp_body)
  end

  test "runs declared page actions as action runs", %{registry: registry} do
    conn =
      :post
      |> json_conn("/services/accounts/surfaces/user_resource/actions/sync/runs", %{
        "payload" => %{"assigns" => %{"label" => "Operator sync"}}
      })
      |> call_api(registry)

    assert conn.status == 200

    assert %{
             "data" => %{
               "type" => "action_run",
               "status" => "succeeded",
               "result" => %{"type" => "job", "id" => "sync", "label" => "Operator sync"}
             }
           } = Jason.decode!(conn.resp_body)
  end

  test "returns RFC 9457 problem details", %{registry: registry} do
    conn = call_api(conn(:get, "/services/missing"), registry)

    assert conn.status == 404
    assert content_type(conn) == "application/problem+json"

    assert %{
             "type" => "about:blank",
             "code" => "unknown-service",
             "title" => "Unknown service",
             "status" => 404,
             "instance" => "/services/missing"
           } = Jason.decode!(conn.resp_body)
  end

  test "rejects unacceptable representations", %{registry: registry} do
    conn =
      :get
      |> conn("/services")
      |> put_req_header("accept", "text/plain")
      |> call_api(registry)

    assert conn.status == 406
    assert content_type(conn) == "application/problem+json"
  end

  test "returns method not allowed with Allow", %{registry: registry} do
    conn =
      :post
      |> conn("/services", %{})
      |> call_api(registry)

    assert conn.status == 405
    assert get_resp_header(conn, "allow") == ["GET"]
    assert content_type(conn) == "application/problem+json"

    assert %{"code" => "method-not-allowed", "status" => 405} = Jason.decode!(conn.resp_body)
  end

  test "rejects unsupported request media types", %{registry: registry} do
    conn =
      :post
      |> conn("/services/accounts/surfaces/user_resource/queries", "{}")
      |> put_req_header("content-type", "text/plain")
      |> call_api(registry)

    assert conn.status == 415
    assert content_type(conn) == "application/problem+json"
  end

  defp json_conn(method, path, body) do
    method
    |> conn(path, body)
    |> put_req_header("content-type", @media_type)
  end

  defp call_api(conn, registry) do
    conn
    |> put_private(:incant_api_registry, registry)
    |> Incant.Web.API.call(@opts)
  end

  defp content_type(conn) do
    conn
    |> get_resp_header("content-type")
    |> List.first()
    |> String.split(";", parts: 2)
    |> hd()
  end

  defp socket_path do
    Path.join(
      System.tmp_dir!(),
      "incant-web-api-#{System.unique_integer([:positive])}.sock"
    )
  end
end
