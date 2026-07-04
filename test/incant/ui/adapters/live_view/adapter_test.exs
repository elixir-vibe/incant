defmodule Incant.UI.Adapters.LiveView.AdapterTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  test "renders table column labels instead of raw ids" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "total_spend_usd", label: "Spend", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "input_tokens", label: "Input tokens", sortable: true}
      ],
      rows: [],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ ">\n            Spend\n"
    assert html =~ ">\n            Input tokens\n"
    refute html =~ ">\n            total_spend_usd\n"
    refute html =~ ">\n            input_tokens\n"
  end

  test "does not render dashboard widget span debug badges" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :requests_over_time,
          type: :timeseries,
          title: "Requests over time",
          value: [1, 2, 3],
          span: 8
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :recent_requests,
          type: :table,
          title: "Recent requests",
          value: [%{model: "gpt", count: 1}],
          span: 4
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "Requests over time"
    assert html =~ "Recent requests"
    refute html =~ ">span 8<"
    refute html =~ ">span 4<"
    refute html =~ ">span auto<"
  end

  test "renders service index links as absolute paths" do
    services = [
      %Incant.Web.API.ServiceSummary{
        id: "llm_proxy",
        key: "llm_proxy",
        service: "llm_proxy",
        version: "1",
        surfaces: %Incant.Web.API.SurfaceCounts{resources: 4, datasets: 0, dashboards: 1}
      }
    ]

    context = %Incant.Live.Context{
      base_path: "/",
      section: "services",
      resources: [],
      datasets: [],
      dashboards: [],
      services: services
    }

    document = Incant.UI.Document.from_context(context)
    env = Incant.UI.Env.new(context, %{admin: nil})

    html = document |> Incant.UI.render(env) |> rendered_to_string()

    assert html =~ ~s(href="/llm_proxy")
    refute html =~ ~s(href="llm_proxy")
    assert html =~ "4"
    assert html =~ "Resources"
  end
end
