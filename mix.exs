defmodule Incant.MixProject do
  use Mix.Project

  def project do
    [
      app: :incant,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      dialyzer: [plt_add_apps: [:mix, :release_kit]],
      releases: releases(),
      deps: deps(),
      aliases: aliases(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
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

  # Run "mix help deps" to learn about dependencies.
  defp description do
    "Phoenix-native admin/control-plane DSL with semantic UI documents, a default LiveView adapter, resources, dashboards, forms, filters, actions, themes, and policies."
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/elixir-vibe/incant"
      },
      files:
        ~w(assets lib mix.exs README.md CHANGELOG.md LICENSE CONVENTIONS.md PLAN.md REFERENCES.md docs)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "CONVENTIONS.md",
        "PLAN.md",
        "REFERENCES.md",
        "docs/install.md",
        "docs/resources.md",
        "docs/dashboards.md",
        "docs/datasets.md",
        "docs/authorization.md",
        "docs/design.md",
        "docs/live-components.md",
        "docs/live-vue-adapter.md",
        "docs/visual-regression.md",
        "docs/platform-admin-roadmap.md",
        "docs/architecture.md",
        "docs/service-interfaces.md",
        "docs/release-checklist.md"
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
      {:safe_rpc, "~> 0.1.12"},
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
