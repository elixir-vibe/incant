defmodule Playground.AdminLiveTest do
  use Playground.ConnCase

  import Phoenix.LiveViewTest

  test "renders Incant resource table", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin/resources/product")

    assert html =~ "Incant"
    assert html =~ "Product"
    assert html =~ "status"
    assert html =~ "Incant Pro"
  end

  test "renders dashboard stat values", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/admin")

    assert html =~ "LLM Proxy"
    assert html =~ "12840"
    assert html =~ "$184.62"
  end

  test "renders access denied when policy rejects dashboard", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/restricted-admin")

    assert html =~ "Access denied"
    refute html =~ "12840"
  end

  test "does not render denied row actions", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/restricted-admin/resources/product")

    assert html =~ "Product"
    assert html =~ "Edit"
    refute html =~ "LLM Proxy"
    refute html =~ "LLMRequest"
    refute html =~ "phx-value-action=\"archive\""
  end

  test "renders unavailable message for denied detail rows", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/restricted-admin/resources/product/2")

    assert html =~ "Record not found or unavailable"
    refute html =~ "Dashboard Wand"
  end

  test "form policies receive submitted attrs without crashing", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/restricted-admin/resources/product/1/edit")

    assert render_change(view, "validate_form", %{"resource" => %{"name" => "Forbidden"}}) =~ "Product"
  end
end
