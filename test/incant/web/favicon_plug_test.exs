defmodule Incant.Web.FaviconPlugTest do
  use ExUnit.Case, async: true

  import Plug.Test

  test "returns a cacheable empty response" do
    conn = Incant.Web.FaviconPlug.call(conn(:get, "/favicon.ico"), [])

    assert conn.status == 204
    assert conn.resp_body == ""
    assert Plug.Conn.get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
  end
end
