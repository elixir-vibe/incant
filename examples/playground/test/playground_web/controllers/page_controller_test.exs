defmodule Playground.PageControllerTest do
  use Playground.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    response = html_response(conn, 200)

    assert response =~ "Incant Playground"
    assert response =~ "LLM Operations"
    assert response =~ "Playground.Admin.Resources.Product"
  end
end
