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
      dialyzer: [plt_add_apps: [:mix]],
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
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
      files: ~w(lib mix.exs README.md CHANGELOG.md CONVENTIONS.md PLAN.md REFERENCES.md docs)
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
        "docs/release-checklist.md"
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
      {:vibe_kit, "~> 0.1"},
      {:igniter, "~> 0.6", runtime: false},
      {:ecto, "~> 3.13"},
      {:phoenix_live_view, "~> 1.1"}
    ]
  end

  defp aliases() do
    [
      ci: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "test",
        "credo --strict",
        "dialyzer",
        "ex_dna --max-clones 0",
        "reach.check --arch --smells"
      ]
    ]
  end
end
