defmodule Incant.Live.ActionsTest do
  use ExUnit.Case, async: true

  alias Incant.ActionResult
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

    assert %ActionResult.Toast{message: "Archived Incant Pro", level: :info} =
             Actions.run(resource, "archive", "1", %{})
  end

  test "normalizes missing callbacks to semantic errors" do
    resource = %Metadata{
      data: fn _params -> [%{id: 1, name: "Incant Pro"}] end,
      table: %Table{actions: [%Action{name: :archive, scope: :row}]}
    }

    assert %ActionResult.Error{message: "archive action is not implemented yet"} =
             Actions.run(resource, "archive", "1", %{})
  end

  test "runs bulk action callbacks with selected rows" do
    callback = fn %{selected_ids: ids, rows: rows}, _assigns ->
      {:ok, ActionResult.toast("Exported #{length(ids)} ids and #{length(rows)} rows")}
    end

    resource = %Metadata{
      data: fn _params -> [%{id: 1, name: "One"}, %{id: 2, name: "Two"}] end,
      table: %Table{
        bulk_actions: [%Action{name: :export, scope: :bulk, opts: [callback: callback]}]
      }
    }

    assert %ActionResult.Toast{message: "Exported 2 ids and 2 rows"} =
             Actions.run_bulk(resource, "export", ["1", "2"], %{})
  end

  test "runs page action callbacks" do
    callback = fn %{resource: resource}, _assigns ->
      ActionResult.job("sync", label: inspect(resource.module))
    end

    resource = %Metadata{
      module: __MODULE__,
      table: %Table{
        page_actions: [%Action{name: :sync, scope: :page, opts: [callback: callback]}]
      }
    }

    assert %ActionResult.Job{id: "sync", label: "Incant.Live.ActionsTest"} =
             Actions.run_page(resource, "sync", %{})
  end
end
