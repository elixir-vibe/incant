defmodule Playground.PageControllerTest do
  use Playground.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Incant Playground"
    assert response =~ "LLM Proxy"
    assert response =~ "Playground.Admin.ProductResource"
  end
end
