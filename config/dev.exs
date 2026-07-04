import Config

config :incant,
  serve?: true,
  registry: [env: System.get_env("INCANT_RPC_BINDINGS_ENV", "HOSTKIT_RPC_BINDINGS")]

config :incant, Incant.Web.Endpoint,
  server: true,
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  http: [
    ip: {127, 0, 0, 1},
    port: String.to_integer(System.get_env("INCANT_HTTP_PORT", "4002"))
  ],
  live_view: [signing_salt: System.get_env("INCANT_LIVE_VIEW_SIGNING_SALT", "incant-live-view")],
  secret_key_base:
    System.get_env(
      "INCANT_SECRET_KEY_BASE",
      "dev-only-incant-secret-key-base-dev-only-incant-secret-key-base-1234"
    ),
  watchers: [
    volt: {Mix.Tasks.Volt.Dev, :run, [~w(--tailwind)]}
  ]

config :volt, :server,
  prefix: "/assets",
  watch_dirs: ["lib/"]

config :logger, :console, format: "[$level] $message\n"
