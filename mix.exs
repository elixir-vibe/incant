defmodule Incant.MixProject do
  use Mix.Project

  @version "0.1.1"
  @source_url "https://github.com/elixir-vibe/incant"

  def project do
    [
      app: :incant,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      name: "Incant",
      description: description(),
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix, :release_kit]],
      releases: releases(),
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  def application do
    [
      mod: {Incant.Application, []},
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [ci: :test]
    ]
  end

  defp description do
    "Elixir/Phoenix admin framework for resources, dashboards, datasets, actions, " <>
      "authorization, and service-owned remote admin surfaces."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(assets config guides lib .formatter.exs mix.exs package.json npm.lock README.md CHANGELOG.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md",
        "guides/introduction/getting-started.md",
        "guides/introduction/library-mode.md",
        "guides/introduction/standalone-mode.md",
        "guides/introduction/project-structure.md",
        "guides/features/resources.md",
        "guides/features/dashboards.md",
        "guides/features/datasets.md",
        "guides/features/authorization.md",
        "guides/features/themes-and-liveview.md",
        "guides/features/distributed-services.md",
        "guides/deployment/standalone-deployment.md",
        "guides/reference/configuration.cheatmd",
        "guides/reference/admin-http-api.cheatmd",
        "guides/internals/architecture.md"
      ],
      groups_for_extras: [
        Introduction: ~r/guides\/introduction\//,
        Features: ~r/guides\/features\//,
        Deployment: ~r/guides\/deployment\//,
        Reference: ~r/guides\/reference\//,
        Internals: ~r/guides\/internals\//
      ],
      groups_for_modules: [
        Core: [
          Incant,
          Incant.Admin,
          Incant.Resource,
          Incant.Dashboard,
          Incant.Dataset,
          Incant.Surface,
          Incant.Session
        ],
        "Data and Forms": [
          Incant.DataSource,
          Incant.Ecto,
          Incant.Query,
          Incant.Result,
          Incant.Form,
          Incant.Forms
        ],
        "Actions and Policy": [
          Incant.ActionResult,
          Incant.Policy,
          Incant.Filter
        ],
        "Distributed Services": [
          Incant.Service,
          Incant.Service.Client,
          Incant.Service.Registry,
          Incant.Service.RegistryServer,
          Incant.Service.Session
        ],
        UI: [
          Incant.UI,
          Incant.UI.Adapter,
          Incant.UI.Document,
          Incant.UI.Adapters.LiveView,
          Incant.Theme,
          Incant.Design
        ],
        Phoenix: [
          Incant.Router,
          Incant.Live.Admin,
          Incant.Web.Endpoint
        ]
      ]
    ]
  end

  defp releases do
    [
      incant: [
        applications: [incant: :permanent]
      ]
    ]
  end

  defp deps do
    [
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:reach, "~> 2.0", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.0", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false},
      {:dsl, "~> 0.1.2"},
      {:vibe_kit, "~> 0.1"},
      {:igniter, "~> 0.6", runtime: false},
      {:release_kit, "~> 0.3", runtime: false},
      {:json_codec, "~> 0.2.3"},
      {:volt, "~> 0.17.2"},
      {:safe_rpc, "~> 0.1.15"},
      {:ecto, "~> 3.13"},
      {:phoenix_live_view, "~> 1.1"},
      {:plug_cowboy, "~> 2.7"}
    ]
  end

  defp aliases() do
    [
      "assets.build": ["volt.build --tailwind"],
      "assets.deploy": ["volt.build --tailwind", "phx.digest"],
      server: ["phx.server"],
      ci: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "npm.ci",
        "volt.js.check --type-aware --type-check",
        "test",
        "credo --strict",
        "dialyzer",
        "ex_dna --max-clones 0",
        "reach.check --arch --smells --strict"
      ]
    ]
  end
end
