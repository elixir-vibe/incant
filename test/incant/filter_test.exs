defmodule Incant.FilterTest do
  use ExUnit.Case, async: true

  alias Incant.Table.Filter

  defmodule Custom do
    @behaviour Incant.Filter

    def control(_filter, _value, _assigns), do: nil
    def match?(_filter, row, value), do: row.custom == value
    def apply_query(_filter, queryable, value, _context), do: {:custom, queryable, value}
  end

  test "resolves built-in filter modules by type" do
    assert Incant.Filter.module(%Filter{name: :title, type: :text}) == Incant.Filters.Text
    assert Incant.Filter.module(%Filter{name: :status, type: :select}) == Incant.Filters.Select

    assert Incant.Filter.module(%Filter{name: :status, type: :multi_select}) ==
             Incant.Filters.MultiSelect

    assert Incant.Filter.module(%Filter{name: :inserted_at, type: :date_range}) ==
             Incant.Filters.DateRange

    assert Incant.Filter.module(%Filter{name: :published, type: :boolean}) ==
             Incant.Filters.Boolean
  end

  test "supports per-filter module overrides" do
    filter = %Filter{name: :custom, type: :text, opts: [filter: Custom]}

    assert Incant.Filter.module(filter) == Custom
    assert Incant.Filter.match?(filter, %{custom: "yes"}, "yes")
    assert Incant.Filter.apply_query(filter, :query, "yes", nil) == {:custom, :query, "yes"}
  end

  test "built-in filters delegate query application to filter callbacks" do
    query = fn queryable, value, context -> {:filtered, queryable, value, context} end
    filter = %Filter{name: :status, type: :select, query: query}

    assert Incant.Filter.apply_query(filter, :query, "published", :context) ==
             {:filtered, :query, "published", :context}
  end

  test "applies multiple filters to queryables" do
    status_query = fn queryable, value, _context -> [{:status, value} | queryable] end
    provider_query = fn queryable, value, _context -> [{:provider, value} | queryable] end

    filters = [
      %Filter{name: :status, type: :select, query: status_query},
      %Filter{name: :provider, type: :select, query: provider_query}
    ]

    assert Incant.Filter.apply_filters(filters, [], %{
             "status" => "ok",
             "provider" => "openai"
           }) == [provider: "openai", status: "ok"]
  end

  test "matches text and select filters against in-memory rows" do
    text = %Filter{name: :title, type: :text}
    select = %Filter{name: :status, type: :select}

    row = %{title: "Phoenix admin", status: :published}

    assert Incant.Filter.match?(text, row, "admin")
    refute Incant.Filter.match?(text, row, "dashboard")
    assert Incant.Filter.match?(select, row, "published")
    refute Incant.Filter.match?(select, row, "draft")
  end

  test "matches multi-select filters" do
    filter = %Filter{name: :provider, type: :multi_select}

    assert Incant.Filter.match?(filter, %{provider: :openai}, ["openai", "anthropic"])
    refute Incant.Filter.match?(filter, %{provider: :google}, ["openai", "anthropic"])
    assert Incant.Filter.match?(filter, %{provider: :google}, [])
  end

  test "matches date range filters" do
    filter = %Filter{name: :inserted_at, type: :date_range}

    assert Incant.Filter.match?(filter, %{inserted_at: ~D[2026-05-31]}, %{
             "from" => "2026-05-01",
             "to" => "2026-06-01"
           })

    refute Incant.Filter.match?(filter, %{inserted_at: ~D[2026-04-30]}, %{
             "from" => "2026-05-01",
             "to" => "2026-06-01"
           })
  end
end
