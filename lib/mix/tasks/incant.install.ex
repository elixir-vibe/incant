defmodule Mix.Tasks.Incant.Install do
  @moduledoc """
  Generates starter Incant admin files and patches Phoenix setup when possible.

  The installer creates:

    * `lib/my_app/admin.ex`
    * `lib/my_app/admin/resources/sample.ex`
    * `lib/my_app/admin/themes/default.ex`

  When it can detect standard Phoenix files, it also adds `use Incant.Router`,
  mounts `incant "/admin", MyApp.Admin`, and adds the Incant Tailwind
  source to `assets/css/app.css`.

  Use Igniter's regular options such as `--dry-run` and `--yes` to preview or
  apply changes.
  """

  use Igniter.Mix.Task

  @shortdoc "Installs starter Incant admin files"

  @impl Igniter.Mix.Task
  def info(_argv, _composing_task) do
    %Igniter.Mix.Task.Info{
      group: :incant,
      example: "mix incant.install --dry-run"
    }
  end

  @impl Igniter.Mix.Task
  def igniter(igniter) do
    app = Mix.Project.config() |> Keyword.fetch!(:app) |> to_string()
    namespace = Macro.camelize(app)

    igniter
    |> Igniter.create_new_file(Path.join(["lib", app, "admin.ex"]), admin_module(namespace),
      on_exists: :warning
    )
    |> Igniter.create_new_file(
      Path.join(["lib", app, "admin", "themes", "default.ex"]),
      theme_module(namespace),
      on_exists: :warning
    )
    |> Igniter.create_new_file(
      Path.join(["lib", app, "admin", "resources", "sample.ex"]),
      sample_resource_module(namespace),
      on_exists: :warning
    )
    |> patch_router(app, namespace)
    |> patch_css()
    |> add_fallback_notice(namespace)
  end

  defp patch_router(igniter, app, namespace) do
    case Enum.find(router_paths(app), &Igniter.exists?(igniter, &1)) do
      nil ->
        Igniter.add_warning(igniter, router_instructions(namespace))

      path ->
        Igniter.update_file(igniter, path, fn source ->
          source
          |> update_content(igniter, &Incant.Install.Patcher.ensure_router_import/1)
          |> update_content(igniter, &Incant.Install.Patcher.ensure_admin_route(&1, namespace))
        end)
    end
  end

  defp patch_css(igniter) do
    case Enum.find(css_paths(), &Igniter.exists?(igniter, &1)) do
      nil ->
        Igniter.add_warning(igniter, css_instructions())

      path ->
        Igniter.update_file(igniter, path, fn source ->
          update_content(source, igniter, &Incant.Install.Patcher.ensure_incant_source/1)
        end)
    end
  end

  defp update_content(source, igniter, updater) do
    content = Rewrite.Source.get(source, :content)
    Igniter.update_source(source, igniter, :content, updater.(content))
  end

  defp router_paths(app) do
    [
      Path.join(["lib", "#{app}_web", "router.ex"]),
      Path.join(["lib", app, "router.ex"])
    ]
  end

  defp css_paths do
    [
      Path.join(["assets", "css", "app.css"]),
      Path.join(["lib", "assets", "css", "app.css"])
    ]
  end

  defp add_fallback_notice(igniter, namespace) do
    Igniter.add_notice(
      igniter,
      "Incant admin generated for #{namespace}. If router or CSS patching was skipped, apply the printed fallback instructions."
    )
  end

  defp router_instructions(namespace) do
    """
    Could not find a Phoenix router to patch. Add Incant manually:

        use Incant.Router

        scope "/" do
          pipe_through :browser
          incant "/admin", #{namespace}.Admin
        end
    """
  end

  defp css_instructions do
    """
    Could not find assets/css/app.css to patch. Add Incant to your Tailwind CSS:

        @source "../deps/incant/lib";
    """
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

      index(&__MODULE__.rows/1)

      def rows(_params) do
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
