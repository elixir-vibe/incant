defmodule IncantPlaygroundWeb.PageControllerTest do
  use IncantPlaygroundWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Incant Playground"
    assert response =~ "LLM Proxy"
    assert response =~ "IncantPlayground.Admin.ProductResource"
  end
end
