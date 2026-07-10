defmodule Incant.Web.NotFoundPlugTest do
  use ExUnit.Case, async: true

  import Plug.Test

  test "returns a plain not found response" do
    conn = Incant.Web.NotFoundPlug.call(conn(:get, "/config"), [])

    assert conn.status == 404
    assert conn.resp_body == "Not Found"
  end
end
