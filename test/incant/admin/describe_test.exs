defmodule Incant.Admin.DescribeTest do
  use ExUnit.Case, async: true

  defmodule Source do
    use Incant.DataSource

    @impl Incant.DataSource
    def query(_query), do: {:ok, []}
  end

  defmodule ProductResource do
    use Incant.Resource,
      schema: Incant.Admin.DescribeTest.Product,
      repo: Incant.Admin.DescribeTest.Repo,
      title: "Products"

    query(&__MODULE__.query/2)

    form do
      field(:name)
      field(:status, :select, options: [:draft, :active])
    end

    table density: :compact do
      column(:name, link: true)
      column(:status, as: :badge)
      filter(:status, :select, options: [:draft, :active], query: &__MODULE__.filter_status/3)
      action(:archive, confirm: true, callback: &__MODULE__.archive/2)

      actions do
        page(:sync, async: true, callback: &__MODULE__.sync/1)
      end

      search([:name])
    end

    def query(query, _context), do: query
    def filter_status(query, _params, _context), do: query
    def archive(_params, _assigns), do: :ok
    def sync(_params), do: :ok
  end

  defmodule UsageDataset do
    use Incant.Dataset, source: Source

    title("Usage")
    from("usage_logs")

    dimensions do
      dimension(:model)
    end

    metrics do
      metric(:requests, :count)
    end

    filters do
      filter(:range, :date_range)
    end

    table do
      group_by([:model])
      columns([:model, :requests])
      sort(:requests, :desc)
    end
  end

  defmodule OperationsDashboard do
    use Incant.Dashboard

    title("Operations")

    variables do
      var(:range, :date_range)
    end

    grid columns: 12 do
      stat(:requests, span: 3, query: &__MODULE__.requests/2)
      table(:recent_usage, span: 6, preview_rows: 7, query: &__MODULE__.requests/2)
    end

    def requests(_vars, _context), do: 0
  end

  defmodule Admin do
    use Incant.Admin, service: :llm_proxy, version: "1"

    resource(ProductResource)
    dashboard(OperationsDashboard)
    dataset(UsageDataset)
  end

  test "describes an admin as a portable contract" do
    assert %Incant.Admin.Contract{} = contract = Incant.Admin.describe(Admin)

    assert contract.id == "llm_proxy"
    assert contract.service == :llm_proxy
    assert contract.version == "1"
    assert contract.module == inspect(Admin)

    assert [%{id: "product_resource", title: "Products"} = resource] = contract.resources
    assert resource.opts == %{title: "Products"}
    refute Map.has_key?(resource.opts, :schema)
    refute Map.has_key?(resource.opts, :repo)

    assert resource.table.columns == [
             %{id: "name", name: :name, opts: %{link: true}},
             %{id: "status", name: :status, opts: %{as: :badge}}
           ]

    assert [%{id: "status", opts: %{options: [:draft, :active]}}] = resource.table.filters
    assert [%{id: "archive", opts: %{confirm: true}}] = resource.table.actions
    refute Map.has_key?(hd(resource.table.actions).opts, :callback)

    assert [%{id: "operations_dashboard", title: "Operations"} = dashboard] = contract.dashboards

    assert [
             %{id: "requests", opts: %{span: 3}},
             %{id: "recent_usage", opts: %{span: 6, preview_rows: 7}}
           ] = dashboard.widgets

    refute Enum.any?(dashboard.widgets, &Map.has_key?(&1.opts, :query))

    assert [%{id: "usage_dataset", title: "Usage"} = dataset] = contract.datasets
    refute Map.has_key?(dataset.opts, :source)
    assert dataset.from == "usage_logs"
    assert dataset.table.group_by == [:model]
  end
end
