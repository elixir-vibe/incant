defmodule Incant.Web.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :incant

  @session_options [
    store: :cookie,
    key: "_incant_key",
    signing_salt: "incant"
  ]

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:incant, :endpoint])
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart], pass: ["*/*"])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(Incant.Web.Router)

  def init(_key, config) do
    config =
      config
      |> Keyword.put_new(:server, Application.get_env(:incant, :serve?, false))
      |> Keyword.put_new(:url, host: "localhost")
      |> Keyword.put_new(:http, ip: {127, 0, 0, 1}, port: 4000)
      |> Keyword.put_new(:secret_key_base, secret_key_base())

    {:ok, config}
  end

  defp secret_key_base do
    Application.get_env(:incant, :secret_key_base) ||
      System.get_env("INCANT_SECRET_KEY_BASE") ||
      String.duplicate("0", 64)
  end
end
