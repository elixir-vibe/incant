defmodule Playground.AdminLiveTest do
  use Playground.ConnCase

  import Phoenix.LiveViewTest

  test "renders catalog products", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/resources/product")

    assert html =~ "Product"
    assert html =~ "Incant Pro"
    assert html =~ "Dashboard Wand"
    assert html =~ "Archive"
  end

  test "renders LLM request table", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/resources/llm_request")

    assert html =~ "LLMRequest"
    assert html =~ "gpt-4.1"
    assert html =~ "claude-sonnet-4"
  end

  test "renders dashboard values from domain data", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin")

    assert html =~ "LLM Operations"
    assert html =~ "3"
    assert html =~ "$68.46"
    assert html =~ "33.33%"
  end

  test "renders dashboard table widget", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/dashboards/llm")

    assert html =~ "Slow requests"
    assert html =~ "gemini-3-pro"
  end
end
