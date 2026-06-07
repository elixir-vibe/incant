defmodule Incant.ActionResultTest do
  use ExUnit.Case, async: true

  alias Incant.ActionResult
  alias Incant.Table.Action

  test "normalizes shorthand success results" do
    action = %Action{name: :archive, scope: :row}

    assert %ActionResult.Toast{message: "archive action completed for 42"} =
             ActionResult.normalize(:ok, action: action, params: %{id: 42})

    assert %ActionResult.Toast{message: "Done"} =
             ActionResult.normalize("Done", action: action, params: %{})

    assert %ActionResult.Toast{message: "Done"} =
             ActionResult.normalize({:ok, "Done"}, action: action, params: %{})
  end

  test "normalizes shorthand errors" do
    assert %ActionResult.Error{message: "Nope"} = ActionResult.normalize({:error, "Nope"})
  end

  test "keeps semantic result structs" do
    result = ActionResult.refresh([:table])
    assert ActionResult.normalize(result) == result
  end

  test "constructs semantic action results" do
    assert %ActionResult.Navigate{to: "/admin", mode: :navigate} =
             ActionResult.navigate("/admin", mode: :navigate)

    assert %ActionResult.Download{id: "file", label: "CSV"} =
             ActionResult.download("file", label: "CSV")

    assert %ActionResult.Job{id: "job", label: "Sync"} = ActionResult.job("job", label: "Sync")

    assert %ActionResult.OpenSurface{surface: :inspector} = ActionResult.open_surface(:inspector)
  end
end
