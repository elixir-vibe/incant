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
    theme_path = Path.join(["lib", app, "admin", "themes", "default.ex"])
    resource_path = Path.join(["lib", app, "admin", "resources", "sample.ex"])

    write_new(admin_path, admin_module(namespace))
    write_new(theme_path, theme_module(namespace))
    write_new(resource_path, sample_resource_module(namespace))

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
      use Incant.Admin, theme: #{namespace}.Admin.Themes.Default

      resource #{namespace}.Admin.Resources.Sample
    end
    """
  end

  defp theme_module(namespace) do
    """
    defmodule #{namespace}.Admin.Themes.Default do
      use Incant.Theme

      css_vars_prefix "--incant"
      palette :zinc
      accent :violet

      tokens do
        color :background, "var(--incant-bg)"
        radius :md, "var(--incant-radius-md)"
        spacing :table_row_height, "var(--incant-table-row-height)"
      end
    end
    """
  end

  defp sample_resource_module(namespace) do
    """
    defmodule #{namespace}.Admin.Resources.Sample do
      use Incant.Resource

      data fn _params ->
        [
          %{id: 1, name: "First row", status: :active},
          %{id: 2, name: "Second row", status: :draft}
        ]
      end

      table do
        column :name, link: true
        column :status, as: :badge
        filter :status, :select, options: [:active, :draft]
      end
    end
    """
  end
end
