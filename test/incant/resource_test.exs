defmodule Incant.ResourceTest do
  use ExUnit.Case, async: true

  defmodule Repo do
  end

  defmodule Post do
  end

  defmodule PostResource do
    use Incant.Resource, schema: Post, repo: Repo

    query(&__MODULE__.index_query/2)
    data(&__MODULE__.rows/1)

    table density: :compact do
      column(:title, link: true)
      column(:status, as: :badge)

      filter(:status, :select, options: [:draft, :published])
      filter(:inserted_at, :date_range)

      action(:edit)
      action(:archive, confirm: true)

      transformer(:sales_performance, query: &__MODULE__.sales_performance/3)

      search([:title, :body])
    end

    def index_query(query, _context), do: query
    def rows(_params), do: []
    def sales_performance(query, _params, _context), do: query
  end

  test "compiles resource metadata" do
    metadata = PostResource.__incant_resource__()

    assert metadata.module == PostResource
    assert metadata.schema == Post
    assert metadata.repo == Repo
    assert metadata.query == (&PostResource.index_query/2)
    assert metadata.data == (&PostResource.rows/1)
    assert metadata.table.opts == [density: :compact]
    assert metadata.table.search == [:title, :body]

    assert Enum.map(metadata.table.columns, & &1.name) == [:title, :status]

    assert Enum.map(metadata.table.filters, & &1.name) == [
             :status,
             :inserted_at,
             :sales_performance
           ]

    assert List.last(metadata.table.filters).type == :transformer
    assert List.last(metadata.table.filters).query == (&PostResource.sales_performance/3)
    assert Enum.map(metadata.table.actions, & &1.name) == [:edit, :archive]
    assert List.last(metadata.table.actions).opts == [confirm: true]
    assert hd(metadata.table.columns).opts == [link: true]
  end

  test "Incant.metadata/1 returns resource metadata" do
    assert Incant.metadata(PostResource) == PostResource.__incant_resource__()
  end
end
