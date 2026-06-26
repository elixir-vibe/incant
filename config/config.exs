import Config

config :incant,
  serve?: false,
  registry: [env: "HOSTKIT_RPC_BINDINGS"]

config :incant, Incant.Web.Endpoint,
  server: false,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: String.duplicate("0", 64)

config :release_kit, :artifact,
  port: 4001,
  health_path: "/health",
  env_clear: %{
    "INCANT_HTTP_IP" => "127.0.0.1",
    "INCANT_HTTP_PORT" => "4001",
    "INCANT_SERVE" => "true",
    "RELEASE_DISTRIBUTION" => "none"
  },
  env_secret: [
    "INCANT_SECRET_KEY_BASE"
  ]
