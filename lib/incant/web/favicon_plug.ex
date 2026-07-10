defmodule Incant.Web.FaviconPlug do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> send_resp(204, "")
  end
end
