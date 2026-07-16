import Config

config :incant,
  serve?: false,
  registry: [env: "HOSTKIT_RPC_BINDINGS"]

config :incant, Incant.Web.Endpoint,
  server: false,
  render_errors: [formats: [html: Incant.Web.ErrorHTML], layout: false],
  url: [host: "localhost"],
  http: [ip: {127, 0, 0, 1}, port: 4000],
  pubsub_server: Incant.PubSub,
  live_view: [signing_salt: "incant-live-view"],
  secret_key_base: String.duplicate("0", 64)

config :volt,
  entry: "assets/js/app.ts",
  root: "assets",
  sources: ["**/*.{js,ts,jsx,tsx}"],
  target: :es2020,
  sourcemap: :hidden,
  resolve_dirs: ["deps"],
  tailwind: [
    css: "assets/css/app.css",
    sources: [
      %{base: "lib/", pattern: "**/*.{ex,heex}"},
      %{base: "assets/", pattern: "**/*.{js,ts,jsx,tsx}"}
    ]
  ]

config :volt, :server,
  prefix: "/assets",
  watch_dirs: ["lib/"]

config :volt, :format,
  print_width: 110,
  semi: true,
  single_quote: false,
  trailing_comma: :all,
  arrow_parens: :always

config :volt, :lint,
  plugins: [:typescript],
  tsgolint: "node_modules/@oxlint-tsgolint/linux-x64/tsgolint",
  rules: %{
    "eqeqeq" => :deny,
    "no-debugger" => :deny,
    "no-duplicate-imports" => :deny,
    "typescript/consistent-type-imports" => :deny,
    "typescript/no-explicit-any" => :deny,
    "typescript/no-floating-promises" => :deny,
    "typescript/no-misused-promises" => :deny
  }

config :volt, :test,
  root: "assets",
  include: ["**/*.{test,spec}.{js,ts,jsx,tsx}"],
  exclude: ["vendor/**", "node_modules/**"],
  timeout: 30_000

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
  ],
  assets: [volt: [tailwind: true, production: true, frozen: true]],
  steps: [after_release: [Incant.Web.ReleaseAssets]]

if File.exists?(Path.expand("#{config_env()}.exs", __DIR__)) do
  import_config "#{config_env()}.exs"
end
