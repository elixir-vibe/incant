defmodule Mix.Tasks.Incant.Install do
  @moduledoc """
  Generates a starter Incant admin module and prints Phoenix setup snippets.
  """

  use Mix.Task

  @shortdoc "Installs starter Incant admin files"

  @impl Mix.Task
  def run(_args) do
    app = Mix.Project.config() |> Keyword.fetch!(:app) |> to_string()
    namespace = app |> Macro.camelize()
    admin_path = Path.join(["lib", app, "admin.ex"])

    write_new(admin_path, admin_module(namespace))

    Mix.shell().info("""

    Add Incant to your router:

        import Incant.Router

        scope "/" do
          pipe_through :browser
          incant_admin "/admin", #{namespace}.Admin
        end

    Add Incant to your Tailwind CSS:

        @source "../deps/incant/lib";

    Copy the default variables from Incant.Design.css_variables/0 into your app CSS.
    """)
  end

  defp write_new(path, content) do
    if File.exists?(path) do
      Mix.shell().info("Keeping existing #{path}")
    else
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, content)
      Mix.shell().info("Created #{path}")
    end
  end

  defp admin_module(namespace) do
    """
    defmodule #{namespace}.Admin do
      use Incant.Admin
    end
    """
  end
end
