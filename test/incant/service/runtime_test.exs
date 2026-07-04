defmodule Incant.Service.RuntimeTest do
  use ExUnit.Case, async: true

  alias Incant.ActionResult
  alias Incant.Service.Runtime

  defmodule Operation do
    use Ecto.Schema

    schema "operations" do
      field(:name, :string)
    end
  end

  defmodule OperationResource do
    use Incant.Resource, schema: Operation

    index(&__MODULE__.index/1)

    table do
      column(:id)

      actions do
        page(:echo_input, callback: {__MODULE__, :echo_input})
      end
    end

    def index(_params), do: []

    def echo_input(_params, assigns) do
      ActionResult.job("echo", meta: %{input: assigns.input})
    end
  end

  defmodule OperationsDashboard do
    use Incant.Dashboard

    stat(:requests, query: &__MODULE__.requests/2)
    table(:recent_requests, query: &__MODULE__.recent_requests/2)

    def requests(%{"range" => range}, %{admin: admin, dashboard: dashboard}) do
      %{range: range, admin: admin.module, dashboard: dashboard.module}
    end

    def recent_requests(_variables, _context) do
      %{
        columns: [:timestamp, :provider, :model, :ok],
        rows: [
          %{
            timestamp: ~U[2026-07-04 10:00:00Z],
            provider: :openai,
            model: "gpt-4.1",
            ok: false
          }
        ]
      }
    end
  end

  defmodule Admin do
    use Incant.Admin, service: :runtime_test, version: "1"

    resource(OperationResource)
    dashboard(OperationsDashboard)
  end

  test "passes action input through to callbacks without flattening it into assigns" do
    assert {:ok, %ActionResult.Job{meta: %{input: %{code: "abc", verifier: "secret"}}}} =
             Runtime.run_action(Admin, "operation_resource", "echo_input", %{
               assigns: %{operator: "dan"},
               input: %{code: "abc", verifier: "secret"}
             })
  end

  test "runs dashboard widget queries in the service runtime" do
    assert {:ok,
            %{
              "range" => "24h",
              "admin" => "Elixir.Incant.Service.RuntimeTest.Admin",
              "dashboard" => "Elixir.Incant.Service.RuntimeTest.OperationsDashboard"
            }} =
             Runtime.run_widget(Admin, "operations_dashboard", "requests", %{"range" => "24h"})
  end

  test "normalizes dashboard widget values for portable service transport" do
    assert {:ok,
            %{
              "columns" => ["timestamp", "provider", "model", "ok"],
              "rows" => [
                %{
                  "timestamp" => "2026-07-04T10:00:00Z",
                  "provider" => "openai",
                  "model" => "gpt-4.1",
                  "ok" => false
                }
              ]
            }} = Runtime.run_widget(Admin, "operations_dashboard", "recent_requests", %{})
  end
end
