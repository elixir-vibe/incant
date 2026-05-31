defmodule Incant.Admin do
  @moduledoc """
  Defines the root Incant admin surface for an application.
  """

  alias Incant.Admin.Metadata

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Incant.Admin

      Module.register_attribute(__MODULE__, :incant_admin_opts, persist: false)

      Module.register_attribute(__MODULE__, :incant_admin_resources,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_admin_dashboards,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_admin_plugins,
        accumulate: true,
        persist: false
      )

      @incant_admin_opts opts
      @before_compile Incant.Admin
    end
  end

  defmacro __before_compile__(env) do
    metadata = %Metadata{
      module: env.module,
      resources: env.module |> Module.get_attribute(:incant_admin_resources) |> Enum.reverse(),
      dashboards: env.module |> Module.get_attribute(:incant_admin_dashboards) |> Enum.reverse(),
      plugins: env.module |> Module.get_attribute(:incant_admin_plugins) |> Enum.reverse(),
      opts: Module.get_attribute(env.module, :incant_admin_opts) || []
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_admin__, do: unquote(escaped)
    end
  end

  defmacro resource(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_resources module
    end
  end

  defmacro dashboard(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_dashboards module
    end
  end

  defmacro plugin(module) do
    quote bind_quoted: [module: module] do
      @incant_admin_plugins module
    end
  end
end
