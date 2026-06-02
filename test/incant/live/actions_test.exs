defmodule Incant.Live.ActionsTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Actions
  alias Incant.Resource.Metadata
  alias Incant.Table
  alias Incant.Table.Action

  test "reports missing action" do
    resource = %Metadata{table: %Table{actions: []}}

    assert Actions.run(resource, "archive", "1", %{}) == {:error, "Unknown action archive"}
  end

  test "reports missing row" do
    resource = %Metadata{
      data: fn _params -> [] end,
      table: %Table{actions: [%Action{name: :archive}]}
    }

    assert Actions.run(resource, "archive", "1", %{}) == {:error, "No row matches 1"}
  end

  test "runs action callbacks" do
    callback = fn %{row: row}, _assigns -> {:ok, "Archived #{row.name}"} end

    resource = %Metadata{
      data: fn _params -> [%{id: 1, name: "Incant Pro"}] end,
      table: %Table{actions: [%Action{name: :archive, opts: [callback: callback]}]}
    }

    assert Actions.run(resource, "archive", "1", %{}) == {:ok, "Archived Incant Pro"}
  end
end
