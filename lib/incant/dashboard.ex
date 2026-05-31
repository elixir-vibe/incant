defmodule Incant.Dashboard do
  @moduledoc """
  Defines a code-first dashboard with variables and widgets.
  """

  alias Incant.Dashboard.Metadata
  alias Incant.Dashboard.{Variable, Widget}

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Incant.Dashboard

      Module.register_attribute(__MODULE__, :incant_dashboard_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_dashboard_title, persist: false)

      Module.register_attribute(__MODULE__, :incant_dashboard_variables,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_dashboard_widgets,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_dashboard_grid, persist: false)

      @incant_dashboard_opts opts
      @before_compile Incant.Dashboard
    end
  end

  defmacro __before_compile__(env) do
    variables = env.module |> Module.get_attribute(:incant_dashboard_variables) |> Enum.reverse()
    widgets = env.module |> Module.get_attribute(:incant_dashboard_widgets) |> Enum.reverse()

    metadata = %Metadata{
      module: env.module,
      title: Module.get_attribute(env.module, :incant_dashboard_title),
      variables:
        Enum.map(variables, fn {name, type, opts} ->
          %Variable{name: name, type: type, opts: opts}
        end),
      widgets:
        Enum.map(widgets, fn {id, type, opts} -> %Widget{id: id, type: type, opts: opts} end),
      grid: Module.get_attribute(env.module, :incant_dashboard_grid) || [],
      opts: Module.get_attribute(env.module, :incant_dashboard_opts) || []
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_dashboard__, do: unquote(escaped)
    end
  end

  defmacro title(value) do
    quote bind_quoted: [value: value] do
      @incant_dashboard_title value
    end
  end

  defmacro variables(do: block) do
    block
  end

  defmacro var(name, type, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      @incant_dashboard_variables {name, type, opts}
    end
  end

  defmacro grid(opts \\ [], do: block) do
    quote do
      @incant_dashboard_grid unquote(opts)
      unquote(block)
    end
  end

  defmacro widget(id, type, opts \\ []) do
    quote bind_quoted: [id: id, type: type, opts: opts] do
      @incant_dashboard_widgets {id, type, opts}
    end
  end

  defmacro stat(id, opts \\ []) do
    quote do
      widget(unquote(id), :stat, unquote(opts))
    end
  end

  defmacro timeseries(id, opts \\ []) do
    quote do
      widget(unquote(id), :timeseries, unquote(opts))
    end
  end

  defmacro table(id, opts \\ []) do
    quote do
      widget(unquote(id), :table, unquote(opts))
    end
  end
end
