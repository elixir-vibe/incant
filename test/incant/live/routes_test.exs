defmodule Incant.Live.RoutesTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Routes

  defmodule Product do
  end

  defmodule LLMRequest do
  end

  defmodule LLM do
  end

  test "builds underscored dashboard paths" do
    dashboard = %{module: LLM}

    assert Routes.dashboard_path("/admin", dashboard) == "/admin/dashboards/llm"
  end

  test "builds underscored resource paths" do
    resource = %{module: LLMRequest}

    assert Routes.resource_path("/admin", resource) == "/admin/resources/llm_request"
    assert Routes.resource_new_path("/admin", resource) == "/admin/resources/llm_request/new"

    assert Routes.resource_detail_path("/admin", resource, 123) ==
             "/admin/resources/llm_request/123"

    assert Routes.resource_edit_path("/admin", resource, 123) ==
             "/admin/resources/llm_request/123/edit"
  end

  test "preserves table query params on resource paths" do
    resource = %{module: Product}

    assert Routes.resource_path("/admin", resource, %{"search" => "wand", "sort" => "-price"}) ==
             "/admin/resources/product?search=wand&sort=-price"
  end

  test "preserves dashboard variable params" do
    dashboard = %{module: LLM}

    assert Routes.dashboard_path("/admin", dashboard, %{
             "var" => %{"range" => "7d", "team" => "core"}
           }) ==
             "/admin/dashboards/llm?var%5Brange%5D=7d&var%5Bteam%5D=core"
  end

  test "drops empty query values" do
    dashboard = %{module: LLM}

    assert Routes.dashboard_path("/admin", dashboard, %{"var" => %{}, "search" => ""}) ==
             "/admin/dashboards/llm"
  end

  test "builds current dashboard path from context" do
    dashboard = %{module: LLM}
    context = %{section: "dashboard", dashboard: dashboard, base_path: "/admin"}

    assert Routes.current_path(%{context: context, params: %{}}, %{"var" => %{"range" => "30d"}}) ==
             "/admin/dashboards/llm?var%5Brange%5D=30d"
  end

  test "builds current resource edit path from context" do
    resource = %{module: Product}

    context = %{
      section: "resource",
      resource: resource,
      base_path: "/admin",
      form_mode: :edit,
      detail_id: "1"
    }

    assert Routes.current_path(%{context: context, params: %{"id" => "1"}}, %{"tab" => "activity"}) ==
             "/admin/resources/product/1/edit?tab=activity"
  end
end
