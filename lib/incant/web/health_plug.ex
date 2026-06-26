defmodule Incant.Web.HealthPlug do
  @moduledoc """
  Minimal health endpoint for standalone Incant deployments.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc false
  def call(conn, _opts) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"status":"ok"}))
  end
end
