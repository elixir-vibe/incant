defmodule Incant.Web.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :incant

  @session_options [
    store: :cookie,
    key: "_incant_key",
    signing_salt: "incant"
  ]

  def init(_key, config) do
    config = Keyword.put_new(config, :live_view, signing_salt: "incant-live-view")
    {:ok, config}
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:incant, :endpoint])
  plug(Plug.Parsers, parsers: [:urlencoded, :multipart], pass: ["*/*"])
  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(Incant.Web.Router)
end
