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

    assert Routes.resource_detail_path("/admin", resource, 123) ==
             "/admin/resources/llm_request/123"
  end

  test "preserves table query params on resource paths" do
    resource = %{module: Product}

    assert Routes.resource_path("/admin", resource, %{"search" => "wand", "sort" => "-price"}) ==
             "/admin/resources/product?search=wand&sort=-price"
  end
end
