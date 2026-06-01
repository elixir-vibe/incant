defmodule IncantPlaygroundWeb.AdminLiveTest do
  use IncantPlaygroundWeb.ConnCase

  import Phoenix.LiveViewTest

  test "renders Incant admin shell", %{conn: conn} do
    {:ok, _view, html} =
      live(conn, ~p"/admin?section=resource&resource=IncantPlayground.Admin.ProductResource")

    assert html =~ "Incant"
    assert html =~ "ProductResource"
    assert html =~ "status"
    assert html =~ "Data execution comes next"
  end
end
