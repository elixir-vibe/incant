defmodule Incant.Live.PaginationTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Rows
  alias Incant.Resource.Metadata
  alias Incant.Table

  test "preserves application-owned pages without paginating them again" do
    resource = %Metadata{
      index: fn %{table: table} ->
        assert table.page == "2"

        %Incant.Result{
          rows: [%{id: 11}, %{id: 12}],
          total_count: 42,
          meta: %{page: 2, page_size: 2, options: %{"model" => ["gpt-5"]}}
        }
      end,
      table: %Table{search: [:name]}
    }

    page =
      Rows.page(resource, %{
        search: "does not re-filter",
        filters: %{},
        sort: "",
        page: "2",
        page_size: "2"
      })

    assert Enum.map(page.rows, & &1.id) == [11, 12]
    assert page.page == 2
    assert page.page_size == 2
    assert page.total == 42
    assert page.total_pages == 21
    assert page.meta == %{options: %{"model" => ["gpt-5"]}}
  end

  test "paginates in-memory rows" do
    rows = for id <- 1..30, do: %{id: id, name: "Row #{id}"}
    resource = %Metadata{index: fn _params -> rows end, table: %Table{}}

    page = Rows.page(resource, %{search: "", filters: %{}, sort: "", page: "2", page_size: "10"})

    assert Enum.map(page.rows, & &1.id) == Enum.to_list(11..20)
    assert page.page == 2
    assert page.page_size == 10
    assert page.total == 30
    assert page.total_pages == 3
  end
end
