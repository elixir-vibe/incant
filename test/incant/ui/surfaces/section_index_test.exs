defmodule Incant.UI.Surfaces.SectionIndexTest do
  use ExUnit.Case, async: true

  alias Incant.UI.Surfaces.SectionIndex

  test "builds navigable dashboard, resource, and dataset sections" do
    assert %SectionIndex{
             title: "Dashboards",
             items: [%{label: "Operations", path: "/llm_proxy/dashboards/operations"}]
           } =
             SectionIndex.from_context(%{
               section: "dashboards",
               base_path: "/llm_proxy",
               dashboards: [%{id: "operations", title: "Operations"}]
             })

    assert %SectionIndex{items: [%{path: "/llm_proxy/resources/api_key"}]} =
             SectionIndex.from_context(%{
               section: "resources",
               base_path: "/llm_proxy",
               resources: [%{id: "api_key", title: "API Keys"}]
             })

    assert %SectionIndex{items: [%{path: "/llm_proxy/datasets/usage"}]} =
             SectionIndex.from_context(%{
               section: "datasets",
               base_path: "/llm_proxy",
               datasets: [%{id: "usage", title: "Usage"}]
             })
  end
end
