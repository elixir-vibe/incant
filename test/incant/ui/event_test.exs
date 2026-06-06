defmodule Incant.UI.EventTest do
  use ExUnit.Case, async: true

  test "serializes normalized event envelope" do
    event = %Incant.UI.Event{
      op: :filter_commit,
      surface: "resource.product.index",
      target: "status",
      value: "active",
      meta: %{"table" => %{}}
    }

    assert Incant.UI.Event.serialize(event) == %{
             "op" => "filter_commit",
             "surface" => "resource.product.index",
             "target" => "status",
             "value" => "active",
             "meta" => %{"table" => %{}}
           }
  end

  test "parses explicit event envelope" do
    assert %Incant.UI.Event{
             op: :row_action,
             target: "archive",
             value: "42",
             meta: %{}
           } =
             Incant.UI.Event.parse(%{
               "op" => "row_action",
               "target" => "archive",
               "value" => "42"
             })
  end

  test "keeps form and filter payloads as implicit meta" do
    event =
      Incant.UI.Event.parse(%{
        "op" => "form_submit",
        "resource" => %{"title" => "Need help"},
        "_target" => ["resource", "title"]
      })

    assert event.op == :form_submit

    assert event.meta == %{
             "resource" => %{"title" => "Need help"},
             "_target" => ["resource", "title"]
           }
  end

  test "unknown ops parse to nil instead of creating atoms" do
    assert %Incant.UI.Event{op: nil} = Incant.UI.Event.parse(%{"op" => "not_real"})
  end
end
