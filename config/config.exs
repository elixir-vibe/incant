import Config

config :incant,
  serve?: false,
  registry: [env: "HOSTKIT_RPC_BINDINGS"]

config :incant, Incant.Web.Endpoint,
  server: false,
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  secret_key_base: String.duplicate("0", 64)
