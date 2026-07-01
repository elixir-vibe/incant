defmodule Incant.Web.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :incant

  @session_options [
    store: :cookie,
    key: "_incant_key",
    signing_salt: "incant"
  ]

  socket("/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]
  )

  plug(Plug.Static,
    at: "/",
    from: :incant,
    gzip: false,
    only: Incant.Web.static_paths()
  )

  if code_reloading? do
    plug(Volt.DevServer, root: "assets")
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:incant, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(Incant.Web.Router)
end
