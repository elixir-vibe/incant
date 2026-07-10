defmodule Incant.Web.NotFoundPlug do
  @moduledoc false

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts), do: send_resp(conn, 404, "Not Found")
end
