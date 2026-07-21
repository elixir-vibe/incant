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

    assert html =~ "LLM Request"
    assert html =~ "gpt-4.1"
    assert html =~ "claude-sonnet-4"
  end

  test "renders dashboard values from domain data", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin")

    assert html =~ "LLM Operations"
    assert html =~ "Requests"
    assert html =~ "Tokens"
    assert html =~ "1.4M"
    assert html =~ "$404.95"
    assert html =~ "1.8s"
  end

  test "renders dashboard table widget", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/dashboards/llm")

    assert html =~ "Slow &amp; failed"
    assert html =~ "gemini-3-pro"
  end

  test "renders form validation errors", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/resources/ticket/new")

    html =
      view
      |> form("[data-incant-resource-form]", %{resource: %{title: ""}})
      |> render_change()

    assert html =~ "can&#39;t be blank"
  end

  test "saves valid form submissions", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/admin/resources/ticket/new")

    html =
      view
      |> form("[data-incant-resource-form]", %{
        resource: %{title: "Need help", priority: "high", status: "open"}
      })
      |> render_submit()

    assert html =~ "Need help"
  end
end
