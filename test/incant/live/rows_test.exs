defmodule Incant.Live.RowsTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Rows
  alias Incant.Resource.Metadata
  alias Incant.Table
  alias Incant.Table.Filter

  defmodule Repo do
    def all({:filtered, schema, status}), do: [%{id: 1, schema: schema, status: status}]
    def all(schema), do: [%{id: 1, schema: schema}]
  end

  defmodule Product do
  end

  test "loads rows from data callbacks" do
    resource = %Metadata{data: fn _params -> [%{id: 1, name: "Incant Pro"}] end, table: %Table{}}

    assert Rows.list(resource, %{search: "", filters: %{}, sort: ""}) == [
             %{id: 1, name: "Incant Pro"}
           ]
  end

  test "loads rows from repo-backed resources" do
    resource = %Metadata{repo: Repo, schema: Product, table: %Table{}}

    assert Rows.list(resource, %{search: "", filters: %{}, sort: ""}) == [
             %{id: 1, schema: Product}
           ]
  end

  test "applies query callbacks and filter query callbacks before repo loading" do
    status_query = fn queryable, value, _context -> {:filtered, queryable, value} end

    resource = %Metadata{
      repo: Repo,
      schema: Product,
      query: fn schema, _context -> schema end,
      table: %Table{filters: [%Filter{name: :status, type: :select, query: status_query}]}
    }

    assert Rows.list(resource, %{search: "", filters: %{"status" => "active"}, sort: ""}) == [
             %{id: 1, schema: Product, status: "active"}
           ]
  end
end
