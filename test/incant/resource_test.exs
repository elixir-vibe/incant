defmodule Incant.ResourceTest do
  use ExUnit.Case, async: true

  defmodule Repo do
  end

  defmodule Post do
  end

  defmodule PostResource do
    use Incant.Resource, schema: Post, repo: Repo

    query(&__MODULE__.index_query/2)
    index(&__MODULE__.rows/1)
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

    assert metadata.id == "post_resource"
    assert metadata.module == PostResource
    assert metadata.schema == Post
    assert metadata.repo == Repo
    assert metadata.query == (&PostResource.index_query/2)
    assert metadata.index == (&PostResource.rows/1)
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

  defmodule AtomCallbackResource do
    use Incant.Resource, schema: Post

    index(:index)
    read(:read)

    def index(_params, _context), do: [%{id: "1", title: "Atom"}]
    def read(id, _context), do: %{id: id, title: "Fetched"}
  end

  defmodule AtomActionResource do
    use Incant.Resource, schema: Post

    table do
      action(:enable, callback: :enable, available_if: :disabled?)

      actions do
        bulk(:archive, callback: :archive)
        page(:sync, callback: :sync)
      end
    end

    def enable(_params, _assigns), do: :ok
    def disabled?(_row, _context), do: true
    def archive(_params, _assigns), do: :ok
    def sync(_params, _assigns), do: :ok
  end

  defmodule ConventionCallbackResource do
    use Incant.Resource, schema: Post

    def index(_params, _context), do: [%{id: "2", title: "Convention"}]
    def read(id, _context), do: %{id: id, title: "Convention fetched"}
  end

  test "Incant.metadata/1 returns resource metadata" do
    assert Incant.metadata(PostResource) == PostResource.__incant_resource__()
  end

  test "resource callbacks can be declared by atom" do
    metadata = Incant.metadata(AtomCallbackResource)

    assert metadata.index == {AtomCallbackResource, :index}
    assert metadata.read == {AtomCallbackResource, :read}
    assert Incant.Live.Rows.raw(metadata, %{}, [], %{}) == [%{id: "1", title: "Atom"}]
    assert Incant.Live.Rows.one(metadata, "9", %{}) == %{id: "9", title: "Fetched"}
  end

  test "action callbacks and predicates can be declared by atom" do
    metadata = Incant.metadata(AtomActionResource)

    assert [enable] = metadata.table.actions
    assert enable.opts[:callback] == {AtomActionResource, :enable}
    assert enable.opts[:available_if] == {AtomActionResource, :disabled?}

    assert hd(metadata.table.bulk_actions).opts[:callback] == {AtomActionResource, :archive}
    assert hd(metadata.table.page_actions).opts[:callback] == {AtomActionResource, :sync}
  end

  test "resource callbacks use conventional index/2 and read/2 when defined" do
    metadata = Incant.metadata(ConventionCallbackResource)

    assert metadata.index == {ConventionCallbackResource, :index}
    assert metadata.read == {ConventionCallbackResource, :read}
    assert Incant.Live.Rows.raw(metadata, %{}, [], %{}) == [%{id: "2", title: "Convention"}]
    assert Incant.Live.Rows.one(metadata, "9", %{}) == %{id: "9", title: "Convention fetched"}
  end
end
