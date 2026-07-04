defmodule Incant.Service.SessionTest do
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

  defmodule OperationsDashboard do
    use Incant.Dashboard

    stat(:users, query: &__MODULE__.users/2)

    table :recent_users, query: &__MODULE__.recent_users/2 do
      column(:name, label: "Name")
      column(:count, label: "Count", format: :number)
    end

    def users(%{"range" => range}, _context), do: %{range: range, count: 2}
    def recent_users(_variables, _context), do: [%{name: "Ada", count: 2}]
  end

  defmodule Admin do
    use Incant.Admin, service: :accounts, version: "1", repo: Repo, rpc: true

    expose(User)
    dashboard(OperationsDashboard)
  end

  defmodule Server do
    use SafeRPC.Adapter.Server, service: Admin
  end

  test "session lists contract surfaces and calls remote service operations" do
    socket = socket_path("session")
    {:ok, server} = Server.start_link(socket: socket)
    bindings = %{accounts: %{socket: socket, modules: [Admin]}}

    assert {:ok, %Incant.Service.Registry{entries: [entry]}} =
             Incant.Service.Registry.from_bindings(bindings)

    session = Incant.Service.Session.new(entry, context: %{actor: %{id: "operator"}})

    assert [%{id: "user", kind: :resource, service: :accounts}] =
             Incant.Service.Session.list_surfaces(session, kind: :resource)

    assert {:ok, %{id: "user", title: "User", kind: :resource}} =
             Incant.Service.Session.fetch_surface(session, "user")

    assert {:ok, %{widgets: widgets}} =
             Incant.Service.Session.fetch_surface(session, "operations_dashboard",
               kind: :dashboard
             )

    assert %Incant.Dashboard.Widget{opts: opts} =
             Enum.find(widgets, &(&1.id == "recent_users"))

    assert [
             %Incant.Dashboard.Column{name: :name, opts: [label: "Name"]},
             %Incant.Dashboard.Column{name: :count, opts: [label: "Count", format: :number]}
           ] = Keyword.fetch!(opts, :columns)

    assert {:ok, %{rows: rows}} = Incant.Service.Session.index(session, "user", %{page: 1})
    assert Enum.map(rows, &Incant.Live.Rows.field(&1, :name)) == ["Ada", "Grace"]

    assert {:ok, row} = Incant.Service.Session.read(session, "user", 1)
    assert Incant.Live.Rows.field(row, :name) == "Ada"

    assert {:ok, %{"range" => "24h", "count" => 2}} =
             Incant.Service.Session.run_widget(session, "operations_dashboard", "users", %{
               "range" => "24h"
             })

    GenServer.stop(server)
  end

  test "session reports unknown surfaces from its loaded contract" do
    socket = socket_path("missing")
    {:ok, server} = Server.start_link(socket: socket)

    assert {:ok, %Incant.Service.Registry{entries: [entry]}} =
             Incant.Service.Registry.from_bindings(%{
               accounts: %{socket: socket, modules: [Admin]}
             })

    session = Incant.Service.Session.new(entry)

    assert {:error, {:unknown_surface, "missing"}} =
             Incant.Service.Session.fetch_surface(session, "missing")

    GenServer.stop(server)
  end

  defp socket_path(name) do
    Path.join(
      System.tmp_dir!(),
      "incant-service-session-#{name}-#{System.unique_integer([:positive])}.sock"
    )
  end
end
