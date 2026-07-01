defmodule Incant.Web.ReleaseAssets do
  @moduledoc false

  @behaviour ReleaseKit.Step

  @impl true
  def run(opts) do
    source = Path.expand(Keyword.get(opts, :source, "priv/static"), File.cwd!())

    if File.dir?(source) do
      target = target_dir(opts)
      File.rm_rf!(target)
      File.mkdir_p!(Path.dirname(target))
      File.cp_r!(source, target)
      Mix.shell().info("* copied Incant static assets to #{Path.relative_to_cwd(target)}")
    else
      Mix.shell().info("* no Incant static assets found at #{Path.relative_to_cwd(source)}")
    end

    :ok
  end

  defp target_dir(opts) do
    app = Mix.Project.config() |> Keyword.fetch!(:app) |> Atom.to_string()
    version = Mix.Project.config() |> Keyword.fetch!(:version)
    release = opts |> Keyword.get(:release, app) |> to_string()

    Path.join([
      Mix.Project.build_path(),
      "rel",
      release,
      "lib",
      "#{app}-#{version}",
      "priv",
      "static"
    ])
  end
end
