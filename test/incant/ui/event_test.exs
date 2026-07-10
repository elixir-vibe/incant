defmodule Incant.UI.EventTest do
  use ExUnit.Case, async: true

  test "constructs normalized event envelope" do
    assert %Incant.UI.Event{
             op: :filter_commit,
             surface: "resource.product.index",
             target: "status",
             value: "active",
             meta: %{"table" => %{}}
           } =
             Incant.UI.Event.filter_commit(
               surface: "resource.product.index",
               target: "status",
               value: "active",
               meta: %{"table" => %{}}
             )
  end

  test "serializes normalized event envelope" do
    event =
      Incant.UI.Event.filter_commit(
        surface: "resource.product.index",
        target: "status",
        value: "active",
        meta: %{"table" => %{}}
      )

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

  test "all public ops parse from adapter payloads" do
    ops = [
      :navigate,
      :filter_commit,
      :filter_clear,
      :search_commit,
      :sort,
      :paginate,
      :row_select,
      :row_select_all,
      :row_action,
      :bulk_action,
      :page_action,
      :form_validate,
      :form_submit,
      :form_cancel,
      :dashboard_variable_commit,
      :widget_refresh
    ]

    for op <- ops do
      assert %Incant.UI.Event{op: ^op} = Incant.UI.Event.parse(%{"op" => to_string(op)})
    end
  end

  test "typed constructors cover all public ops" do
    constructors = [
      :navigate,
      :filter_commit,
      :filter_clear,
      :search_commit,
      :sort,
      :paginate,
      :row_select,
      :row_select_all,
      :row_action,
      :bulk_action,
      :page_action,
      :form_validate,
      :form_submit,
      :form_cancel,
      :dashboard_variable_commit,
      :widget_refresh
    ]

    for constructor <- constructors do
      assert %Incant.UI.Event{op: op} = apply(Incant.UI.Event, constructor, [[target: "target"]])
      assert op == constructor
    end
  end

  test "unknown ops parse to nil instead of creating atoms" do
    assert %Incant.UI.Event{op: nil} = Incant.UI.Event.parse(%{"op" => "not_real"})
  end
end
