defmodule Incant.Service.IndexTest do
  use ExUnit.Case, async: true

  alias Incant.Service.Index

  test "casts the explicit portable table-state fields" do
    assert {:ok,
            %{
              page: 2,
              page_size: 50,
              search: "codex",
              sort: "timestamp:desc",
              filters: %{"model" => "gpt-5.5"}
            }} =
             Index.cast_params(%{
               "page" => "2",
               "page_size" => 50,
               "search" => "codex",
               "sort" => "timestamp:desc",
               "filters" => %{"model" => "gpt-5.5"}
             })
  end

  test "rejects wrapper shapes, unknown fields, and invalid values" do
    assert {:error, {:unknown_table_field, "table"}} =
             Index.cast_params(%{"table" => %{"page" => 2}})

    assert {:error, {:unknown_table_field, "selected_ids"}} =
             Index.cast_params(%{"selected_ids" => []})

    assert {:error, {:invalid_table_field, :page, 0}} = Index.cast_params(%{"page" => 0})
  end

  test "dumps internal table state with portable string keys" do
    assert Index.dump_params(%{page: 2, filters: %{"model" => "gpt-5.5"}}) == %{
             "page" => 2,
             "filters" => %{"model" => "gpt-5.5"}
           }
  end
end
