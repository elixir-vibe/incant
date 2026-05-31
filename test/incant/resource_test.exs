defmodule Incant.ResourceTest do
  use ExUnit.Case, async: true

  defmodule Repo do
  end

  defmodule Post do
  end

  defmodule PostResource do
    use Incant.Resource, schema: Post, repo: Repo

    query(&__MODULE__.index_query/2)

    table density: :compact do
      column(:title, link: true)
      column(:status, as: :badge)

      filter(:status, :select, options: [:draft, :published])
      filter(:inserted_at, :date_range)

      search([:title, :body])
    end

    def index_query(query, _context), do: query
  end

  test "compiles resource metadata" do
    metadata = PostResource.__incant_resource__()

    assert metadata.module == PostResource
    assert metadata.schema == Post
    assert metadata.repo == Repo
    assert metadata.query == (&PostResource.index_query/2)
    assert metadata.table.opts == [density: :compact]
    assert metadata.table.search == [:title, :body]

    assert Enum.map(metadata.table.columns, & &1.name) == [:title, :status]
    assert Enum.map(metadata.table.filters, & &1.name) == [:status, :inserted_at]
    assert hd(metadata.table.columns).opts == [link: true]
  end

  test "Incant.metadata/1 returns resource metadata" do
    assert Incant.metadata(PostResource) == PostResource.__incant_resource__()
  end
end
