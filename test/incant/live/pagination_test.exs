defmodule Incant.Live.PaginationTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Rows
  alias Incant.Resource.Metadata
  alias Incant.Table

  test "paginates in-memory rows" do
    rows = for id <- 1..30, do: %{id: id, name: "Row #{id}"}
    resource = %Metadata{data: fn _params -> rows end, table: %Table{}}

    page = Rows.page(resource, %{search: "", filters: %{}, sort: "", page: "2", page_size: "10"})

    assert Enum.map(page.rows, & &1.id) == Enum.to_list(11..20)
    assert page.page == 2
    assert page.page_size == 10
    assert page.total == 30
    assert page.total_pages == 3
  end
end
