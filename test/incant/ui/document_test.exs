defmodule Incant.UI.DocumentTest do
  use ExUnit.Case, async: true

  defmodule Admin do
  end

  defmodule Product do
  end

  defmodule ProductResource do
    use Incant.Resource, schema: Product

    table do
      column(:name, link: true)
      column(:status, as: :badge)
      filter(:status, :select, options: [:draft, :active])
      filter(:inserted_at, :date_range)
      action(:archive, tone: :danger)
      search([:name])
    end
  end

  defmodule OperationsDashboard do
    use Incant.Dashboard

    title("Operations")

    variables do
      var(:range, :date_range)
      var(:provider, :select, options: [:openai, :anthropic])
    end

    grid columns: 12, row_height: 8 do
      stat(:total_requests, span: 3)
    end
  end

  test "builds resource index document" do
    resource = Incant.metadata(ProductResource)

    document =
      context(resource: resource, resources: [resource])
      |> Incant.UI.Document.from_context(page_title: "Product")

    assert document.title == "Product"
    assert %Incant.UI.Surfaces.ResourceIndex{} = document.surface
    assert document.nav.active_id == "resource.#{ProductResource}"
    assert document.surface.filter_bar.search.role == :search

    assert Enum.map(document.surface.filter_bar.filters, & &1.__struct__) == [
             Incant.UI.Controls.Select,
             Incant.UI.Controls.DateRange
           ]

    assert Enum.map(document.surface.table.columns, & &1.id) == ["name", "status"]
    assert Enum.map(document.surface.table.row_actions, & &1.name) == [:archive]
  end

  test "builds dashboard document" do
    dashboard = Incant.metadata(OperationsDashboard)

    document =
      context(section: "dashboard", dashboard: dashboard, dashboards: [dashboard])
      |> Incant.UI.Document.from_context(page_title: "Operations")

    assert %Incant.UI.Surfaces.Dashboard{} = document.surface
    assert document.nav.active_id == "dashboard.#{OperationsDashboard}"

    assert Enum.map(document.surface.variables, & &1.__struct__) == [
             Incant.UI.Controls.DateRange,
             Incant.UI.Controls.Select
           ]

    assert [%Incant.UI.Regions.WidgetGrid.Widget{id: :total_requests, type: :stat}] =
             document.surface.widgets
  end

  defp context(overrides) do
    resource = Keyword.get(overrides, :resource)
    dashboard = Keyword.get(overrides, :dashboard)

    struct!(
      Incant.Live.Context,
      Keyword.merge(
        [
          admin: %{module: Admin},
          base_path: "/admin",
          resources: [],
          dashboards: [],
          section: if(dashboard, do: "dashboard", else: "resource"),
          resource: resource,
          dashboard: dashboard,
          table_state: %{search: "", filters: %{}, sort: "", page: 1, page_size: 25},
          rows: [],
          pagination: %{page: 1, page_size: 25, total: 0, total_pages: 1},
          dashboard_variables: %{},
          widget_values: %{},
          authorization: :ok
        ],
        overrides
      )
    )
  end
end
