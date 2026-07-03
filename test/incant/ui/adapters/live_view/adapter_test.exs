defmodule Incant.UI.Adapters.LiveView.AdapterTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

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
