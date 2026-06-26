defmodule Incant.Admin do
  @moduledoc """
  Defines the root Incant admin surface for an application.

  Admin modules wire resources, dashboards, plugins, and global options together.

      defmodule MyApp.Admin do
        use Incant.Admin,
          repo: MyApp.Repo,
          theme: MyApp.Admin.Themes.Default,
          policy: MyApp.Admin.Policy,
          actor_assign: :current_scope

        resource MyApp.Admin.Resources.Product
        dashboard MyApp.Admin.Dashboards.Operations
      end
  """

  alias Incant.Admin.{Contract, Metadata}

  @doc "Returns a transport-safe contract for an admin module or metadata struct."
  @spec describe(module | Metadata.t()) :: Contract.t()
  def describe(admin_or_metadata), do: Incant.Admin.Describe.describe(admin_or_metadata)

  @doc "Returns all resolved admin surfaces in declaration order."
  def surfaces(admin_or_metadata), do: Incant.Admin.SurfaceResolver.surfaces(admin_or_metadata)

  @doc "Returns resolved resource surfaces."
  def resources(admin_or_metadata), do: Incant.Admin.SurfaceResolver.resources(admin_or_metadata)

  @doc "Returns resolved dashboard surfaces."
  def dashboards(admin_or_metadata),
    do: Incant.Admin.SurfaceResolver.dashboards(admin_or_metadata)

  @doc "Returns resolved dataset surfaces."
  def datasets(admin_or_metadata), do: Incant.Admin.SurfaceResolver.datasets(admin_or_metadata)

  defmacro __using__(opts \\ []) do
    rpc_ast = rpc_ast(opts)

    quote bind_quoted: [opts: opts], unquote: true do
      import Incant.Admin, except: [describe: 1]

      Module.register_attribute(__MODULE__, :incant_admin_opts, persist: false)

      Module.register_attribute(__MODULE__, :incant_admin_resources,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_admin_exposed,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_admin_dashboards,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_admin_datasets,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_admin_plugins,
        accumulate: true,
        persist: false
      )

      @incant_admin_opts opts
      @before_compile Incant.Admin

      unquote(rpc_ast)
    end
  end

  defmacro __before_compile__(env) do
    metadata = %Metadata{
      module: env.module,
      resources: env.module |> Module.get_attribute(:incant_admin_resources) |> Enum.reverse(),
      exposed: env.module |> Module.get_attribute(:incant_admin_exposed) |> Enum.reverse(),
      dashboards: env.module |> Module.get_attribute(:incant_admin_dashboards) |> Enum.reverse(),
      datasets: env.module |> Module.get_attribute(:incant_admin_datasets) |> Enum.reverse(),
      plugins: env.module |> Module.get_attribute(:incant_admin_plugins) |> Enum.reverse(),
      opts: Module.get_attribute(env.module, :incant_admin_opts) || []
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_admin__, do: unquote(escaped)
    end
  end

  defp rpc_ast(opts) do
    if Keyword.get(opts, :rpc, false) do
      quote do
        use Incant.Admin.RPC, unquote(opts)
      end
    else
      quote(do: :ok)
    end
  end

  defmacro resource(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_resources module
    end
  end

  defmacro expose(schema, opts \\ []) do
    quote bind_quoted: [schema: schema, opts: opts] do
      @incant_admin_exposed {schema, opts}
    end
  end

  defmacro dashboard(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_dashboards module
    end
  end

  defmacro dataset(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_datasets module
    end
  end

  defmacro plugin(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_plugins module
    end
  end
end
