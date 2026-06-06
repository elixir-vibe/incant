# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :playground,
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :playground, Playground.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: Playground.ErrorHTML, json: Playground.ErrorJSON],
    layout: false
  ],
  pubsub_server: Playground.PubSub,
  live_view: [signing_salt: "AXa04QN1"]

config :volt,
  entry: "assets/js/app.js",
  outdir: "priv/static/assets",
  root: "assets",
  target: :es2022,
  resolve_dirs: [Path.expand("../deps", __DIR__), Mix.Project.build_path()],
  aliases: %{"@" => "."},
  tailwind: [
    css: "assets/css/app.css",
    sources: [
      %{base: "lib/", pattern: "**/*.{ex,heex}"},
      %{base: "assets/", pattern: "**/*.{js,ts,jsx,tsx}"},
      %{base: "../../lib/", pattern: "**/*.ex"}
    ]
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
