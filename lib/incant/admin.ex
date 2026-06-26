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
    rpc_ast = rpc_definitions(metadata)

    quote do
      @doc false
      def __incant_admin__, do: unquote(escaped)

      unquote(rpc_ast)
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

  defp rpc_definitions(%Metadata{opts: opts} = metadata) do
    if Keyword.get(opts, :rpc, false) do
      contract = Incant.Admin.Describe.describe(metadata)

      quote do
        @rpc true
        @doc "Describe this Incant admin surface."
        @spec describe(Incant.Service.Describe.t(), map(), term()) ::
                {:ok, Incant.Admin.Contract.t()} | {:error, term()}
        def describe(%Incant.Service.Describe{context: context}, meta, state) do
          _safe_rpc_boundary_contract = unquote(Macro.escape(contract))
          describe(__incant_rpc_context__(context, meta, state))
        end

        @rpc true
        @doc "Index an Incant surface."
        @spec index(Incant.Service.Index.t(), map(), term()) :: {:ok, map()} | {:error, term()}
        def index(%Incant.Service.Index{} = request, meta, state) do
          _safe_rpc_boundary_page = %{
            rows: [],
            page: 1,
            page_size: 25,
            total: 0,
            total_pages: 1,
            error: nil
          }

          index(
            request.surface_id,
            request.params,
            __incant_rpc_context__(request.context, meta, state)
          )
        end

        @rpc true
        @doc "Read one item from an Incant surface."
        @spec read(Incant.Service.Read.t(), map(), term()) :: {:ok, term()} | {:error, term()}
        def read(%Incant.Service.Read{} = request, meta, state) do
          _safe_rpc_boundary_contract = unquote(Macro.escape(contract))

          read(
            request.surface_id,
            request.id,
            __incant_rpc_context__(request.context, meta, state)
          )
        end

        @rpc true
        @doc "Run an Incant surface action."
        @spec run_action(Incant.Service.RunAction.t(), map(), term()) ::
                {:ok, Incant.ActionResult.t()} | {:error, term()}
        def run_action(%Incant.Service.RunAction{} = request, meta, state) do
          _safe_rpc_boundary_action_results = [
            %Incant.ActionResult.Toast{},
            %Incant.ActionResult.Error{},
            %Incant.ActionResult.Refresh{},
            %Incant.ActionResult.Navigate{},
            %Incant.ActionResult.Download{},
            %Incant.ActionResult.Job{},
            %Incant.ActionResult.OpenSurface{}
          ]

          run_action(
            request.surface_id,
            request.action_id,
            request.payload,
            __incant_rpc_context__(request.context, meta, state)
          )
        end
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
