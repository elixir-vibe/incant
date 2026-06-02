defmodule Incant.EctoFiltersTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  alias Incant.Filter
  alias Incant.Table.Filter, as: TableFilter

  test "select filters add Ecto where clauses by default" do
    query =
      Filter.apply_query(
        %TableFilter{name: :status, type: :select},
        from(p in "products"),
        "active",
        %{}
      )

    assert %Ecto.Query{} = query
    assert length(query.wheres) == 1
  end

  test "text filters add Ecto ilike clauses by default" do
    query =
      Filter.apply_query(
        %TableFilter{name: :name, type: :text},
        from(p in "products"),
        "incant",
        %{}
      )

    assert %Ecto.Query{} = query
    assert length(query.wheres) == 1
  end

  test "custom query callbacks take precedence" do
    callback = fn queryable, value, _context -> {:custom, queryable, value} end

    assert Filter.apply_query(
             %TableFilter{name: :status, type: :select, query: callback},
             :query,
             "active",
             %{}
           ) ==
             {:custom, :query, "active"}
  end
end
