import Config

if config_env() == :prod do
  serve? = System.get_env("INCANT_SERVE") in ["1", "true", "TRUE"]
  port = String.to_integer(System.get_env("INCANT_HTTP_PORT", "4000"))

  config :incant,
    serve?: serve?,
    registry: [env: System.get_env("INCANT_RPC_BINDINGS_ENV", "HOSTKIT_RPC_BINDINGS")]

  config :incant, Incant.Web.Endpoint,
    server: serve?,
    http: [
      ip:
        System.get_env("INCANT_HTTP_IP", "127.0.0.1")
        |> String.to_charlist()
        |> :inet.parse_address()
        |> case do
          {:ok, ip} -> ip
          {:error, _reason} -> {127, 0, 0, 1}
        end,
      port: port
    ],
    url: [host: "localhost", port: port],
    check_origin: ["//localhost:#{port}", "//127.0.0.1:#{port}"],
    live_view: [signing_salt: System.get_env("INCANT_LIVE_VIEW_SIGNING_SALT", "incant-live-view")],
    secret_key_base: System.fetch_env!("INCANT_SECRET_KEY_BASE")
end
