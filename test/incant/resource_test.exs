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
    changeset(&__MODULE__.changeset/2)

    form do
      field(:title)
      field(:status, :select, options: [:draft, :published])
    end

    table density: :compact do
      column(:title, link: true)
      column(:status, as: :badge)

      filter(:status, :select, options: [:draft, :published])
      filter(:inserted_at, :date_range)

      action(:edit)
      action(:archive, confirm: true)
      row_detail(:activity, label: "Activity")

      actions do
        bulk(:export_selected, result: :download)
        page(:sync, async: true, result: :job)
      end

      transformer(:sales_performance, query: &__MODULE__.sales_performance/3)

      search([:title, :body])
    end

    def index_query(query, _context), do: query
    def rows(_params), do: []
    def changeset(record, attrs), do: {record, attrs}
    def sales_performance(query, _params, _context), do: query
  end

  test "compiles resource metadata" do
    metadata = PostResource.__incant_resource__()

    assert metadata.module == PostResource
    assert metadata.schema == Post
    assert metadata.repo == Repo
    assert metadata.query == (&PostResource.index_query/2)
    assert metadata.data == (&PostResource.rows/1)
    assert metadata.changeset == (&PostResource.changeset/2)
    assert metadata.form.opts == []
    assert Enum.map(metadata.form.fields, & &1.name) == [:title, :status]
    assert List.last(metadata.form.fields).type == :select
    assert List.last(metadata.form.fields).opts == [options: [:draft, :published]]
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
    assert Enum.map(metadata.table.actions, & &1.scope) == [:row, :row]
    assert List.last(metadata.table.actions).opts == [confirm: true]
    assert Enum.map(metadata.table.bulk_actions, & &1.name) == [:export_selected]
    assert hd(metadata.table.bulk_actions).scope == :bulk
    assert hd(metadata.table.bulk_actions).opts == [result: :download]
    assert Enum.map(metadata.table.page_actions, & &1.name) == [:sync]
    assert hd(metadata.table.page_actions).scope == :page
    assert hd(metadata.table.page_actions).opts == [async: true, result: :job]
    assert metadata.table.row_detail == {:activity, [label: "Activity"]}
    assert hd(metadata.table.columns).opts == [link: true]
  end

  test "Incant.metadata/1 returns resource metadata" do
    assert Incant.metadata(PostResource) == PostResource.__incant_resource__()
  end
end
