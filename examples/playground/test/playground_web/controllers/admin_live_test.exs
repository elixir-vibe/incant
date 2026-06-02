defmodule Playground.AdminLiveTest do
  use Playground.ConnCase

  import Phoenix.LiveViewTest

  test "renders Incant resource table", %{conn: conn} do
    {:ok, _view, html} =
      live(conn, ~p"/admin?section=resource&resource=Playground.Admin.Resources.Product")

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
end
