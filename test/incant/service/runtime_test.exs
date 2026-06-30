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

  defmodule Admin do
    use Incant.Admin, service: :runtime_test, version: "1"

    resource(OperationResource)
  end

  test "passes action input through to callbacks without flattening it into assigns" do
    assert {:ok, %ActionResult.Job{meta: %{input: %{code: "abc", verifier: "secret"}}}} =
             Runtime.run_action(Admin, "operation_resource", "echo_input", %{
               assigns: %{operator: "dan"},
               input: %{code: "abc", verifier: "secret"}
             })
  end
end
