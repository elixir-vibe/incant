defmodule Incant.Live.RowsTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Rows
  alias Incant.Resource.Metadata
  alias Incant.Table
  alias Incant.Table.Filter

  defmodule Repo do
    def all(%Ecto.Query{} = query),
      do: [%{id: 1, limit: query.limit.expr, offset: query.offset.expr}]

    def all({:filtered, schema, status}), do: [%{id: 1, schema: schema, status: status}]
    def all({:scoped, schema, actor}), do: [%{id: 1, schema: schema, actor: actor}]
    def all(schema), do: [%{id: 1, schema: schema}]
    def aggregate(%Ecto.Query{}, :count), do: 42
    def aggregate({:scoped, _schema, _actor}, :count), do: 1
  end

  defmodule Product do
  end

  defmodule Policy do
    def scope_rows(actor, _resource, rows, _context) do
      Enum.filter(rows, &(&1.owner_id == actor.id))
    end

    def scope_query(actor, _resource, queryable, _context), do: {:scoped, queryable, actor.id}
  end

  defmodule QueryProduct do
    use Ecto.Schema

    schema "products" do
      field(:name, :string)
    end
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

  test "applies query-level pagination when loading Ecto queries" do
    resource = %Metadata{repo: Repo, schema: QueryProduct, table: %Table{}}

    assert [%{limit: limit, offset: offset}] =
             Rows.list(resource, %{search: "", filters: %{}, sort: "", page: "2", page_size: "10"})

    assert limit != nil
    assert offset != nil

    page = Rows.page(resource, %{search: "", filters: %{}, sort: "", page: "2", page_size: "10"})
    assert page.total == 42
    assert page.total_pages == 5
  end

  test "scopes data rows with policy scope_rows callback" do
    resource = %Metadata{
      data: fn _params -> [%{id: 1, owner_id: 1}, %{id: 2, owner_id: 2}] end,
      table: %Table{}
    }

    context = %{admin: %{opts: [policy: Policy]}, actor: %{id: 1}}

    assert Rows.list(resource, %{search: "", filters: %{}, sort: ""}, context) == [
             %{id: 1, owner_id: 1}
           ]
  end

  test "scopes repo queries with policy scope_query callback" do
    resource = %Metadata{repo: Repo, schema: Product, table: %Table{}}
    context = %{admin: %{opts: [policy: Policy]}, actor: %{id: 7}}

    assert Rows.list(resource, %{search: "", filters: %{}, sort: ""}, context) == [
             %{id: 1, schema: Product, actor: 7}
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
