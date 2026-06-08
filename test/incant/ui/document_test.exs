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
      row_detail(:activity, label: "Activity")

      actions do
        bulk(:export_selected, result: :download)
        page(:sync, async: true, result: :job)
      end

      search([:name])
    end

    form do
      field(:name)
      field(:status, :select, options: [:draft, :active])
    end
  end

  defmodule AnalyticsSource do
    use Incant.DataSource

    @impl Incant.DataSource
    def query(_query), do: {:ok, [%{campaign: "brand", clicks: 12}]}
  end

  defmodule CampaignDataset do
    use Incant.Dataset, source: AnalyticsSource

    title("Campaigns")
    from("campaign_daily")

    dimensions do
      dimension(:campaign)
    end

    metrics do
      metric(:clicks, :sum)
    end

    filters do
      filter(:campaign, :select, options: ["brand", "search"])
    end

    table do
      group_by([:campaign])
      columns([:campaign, :clicks])
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
    assert Enum.map(document.surface.table.bulk_actions, & &1.name) == [:export_selected]
    assert Enum.map(document.surface.table.page_actions, & &1.name) == [:sync]
    assert document.surface.table.selection.enabled == true
    assert document.surface.table.row_detail.id == "activity"
  end

  test "builds resource detail document" do
    resource = Incant.metadata(ProductResource)

    document =
      context(
        resource: resource,
        resources: [resource],
        selected_row: %{id: 12, name: "Notebook", status: :active}
      )
      |> Incant.UI.Document.from_context(page_title: "Notebook")

    assert %Incant.UI.Surfaces.ResourceIndex{detail: detail, form: nil} = document.surface
    assert detail.title == "Notebook"
    assert Enum.map(detail.fields, & &1.id) == ["name", "status"]
  end

  test "builds new form document" do
    resource = Incant.metadata(ProductResource)

    document =
      context(
        resource: resource,
        resources: [resource],
        form_mode: :new,
        form_record: %{},
        form_changeset: %{}
      )
      |> Incant.UI.Document.from_context(page_title: "New Product")

    assert %Incant.UI.Surfaces.ResourceIndex{form: form, detail: nil} = document.surface
    assert form.mode == :new
    assert Enum.map(form.fields, & &1.name) == ["name", "status"]
  end

  test "builds edit form document" do
    resource = Incant.metadata(ProductResource)

    document =
      context(
        resource: resource,
        resources: [resource],
        selected_row: %{id: 12, name: "Notebook", status: :active},
        form_mode: :edit,
        form_record: %{id: 12, name: "Notebook", status: :active},
        form_changeset: %{name: "Notebook", status: :active}
      )
      |> Incant.UI.Document.from_context(page_title: "Edit Product")

    assert %Incant.UI.Surfaces.ResourceIndex{form: form, detail: nil} = document.surface
    assert form.mode == :edit
    assert Enum.map(form.fields, & &1.value) == ["Notebook", :active]
  end

  test "builds empty document for denied or unmatched contexts" do
    document =
      context(resource: nil, section: nil, authorization: {:error, {:unauthorized, :index}})
      |> Incant.UI.Document.from_context(page_title: "Denied")

    assert %Incant.UI.Surfaces.Empty{context: %{authorization: {:error, {:unauthorized, :index}}}} =
             document.surface
  end

  test "builds dataset document" do
    dataset = Incant.metadata(CampaignDataset)
    {:ok, result} = Incant.Dataset.run(dataset)

    document =
      context(section: "dataset", dataset: dataset, datasets: [dataset], dataset_result: result)
      |> Incant.UI.Document.from_context(page_title: "Campaigns")

    assert %Incant.UI.Surfaces.DatasetIndex{} = document.surface
    assert document.nav.active_id == "dataset.#{CampaignDataset}"
    assert [%Incant.UI.Controls.Select{name: "campaign"}] = document.surface.filter_bar.filters
    assert Enum.map(document.surface.table.columns, & &1.id) == ["campaign", "clicks"]
    assert [%{cells: cells}] = document.surface.table.rows
    assert Enum.map(cells, & &1.value) == ["brand", 12]
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
          datasets: [],
          section: if(dashboard, do: "dashboard", else: "resource"),
          resource: resource,
          dashboard: dashboard,
          dataset: nil,
          form_mode: nil,
          form_record: nil,
          form_changeset: nil,
          selected_row: nil,
          dataset_result: nil,
          table_state: %{
            search: "",
            filters: %{},
            sort: "",
            page: 1,
            page_size: 25,
            selected_ids: []
          },
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
