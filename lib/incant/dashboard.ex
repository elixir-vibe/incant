defmodule Incant.Dashboard do
  @moduledoc """
  Defines a code-first dashboard with variables and widgets.

      defmodule MyApp.Admin.Dashboards.Operations do
        use Incant.Dashboard

        title "Operations"

        variables do
          var :range, :date_range
        end

        grid columns: 12 do
          stat :total_requests, span: 3, query: &MyApp.Admin.Metrics.total_requests/2

          table :slow_requests, span: 6, query: &MyApp.Admin.Metrics.slow_requests/2 do
            column :timestamp, label: "Timestamp", format: :datetime
            column :duration_ms, label: "Duration", format: :number
          end
        end
      end
  """

  alias Incant.Dashboard.Metadata
  alias Incant.Dashboard.Scope
  alias Incant.Dashboard.Variable

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Incant.Dashboard

      Module.register_attribute(__MODULE__, :incant_dashboard_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_dashboard_title, persist: false)

      Module.register_attribute(__MODULE__, :incant_dashboard_variables,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_dashboard_grid, persist: false)
      Module.register_attribute(__MODULE__, :incant_dashboard_chart_opts, persist: false)

      Scope.start_dashboard()

      @incant_dashboard_opts opts
      @before_compile Incant.Dashboard
    end
  end

  defmacro __before_compile__(env) do
    variables = env.module |> Module.get_attribute(:incant_dashboard_variables) |> Enum.reverse()
    dashboard_scope = Scope.finish_dashboard()

    metadata = %Metadata{
      module: env.module,
      title: Module.get_attribute(env.module, :incant_dashboard_title),
      variables:
        Enum.map(variables, fn {name, type, opts} ->
          %Variable{name: name, type: type, opts: opts}
        end),
      widgets: dashboard_scope.widgets,
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

  defmacro variables(do: block), do: block

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
      Scope.add_widget(id, type, opts)
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
    quote bind_quoted: [id: id, opts: opts] do
      Scope.add_widget(id, :table, opts)
    end
  end

  defmacro table(id, opts, do: block) do
    quote do
      Scope.start_table_widget(unquote(id), unquote(opts))
      unquote(block)
      Scope.finish_table_widget()
    end
  end

  defmacro column(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      Scope.add_column(name, opts)
    end
  end

  defmacro chart(id, type, opts \\ []) do
    quote do
      widget(unquote(id), :chart, Keyword.put(unquote(opts), :chart_type, unquote(type)))
    end
  end

  defmacro chart(id, type, opts, do: block) do
    quote do
      @incant_dashboard_chart_opts []
      unquote(block)

      widget(
        unquote(id),
        :chart,
        unquote(opts)
        |> Keyword.put(:chart_type, unquote(type))
        |> Keyword.merge(@incant_dashboard_chart_opts || [])
      )

      @incant_dashboard_chart_opts nil
    end
  end

  defmacro dataset(module) do
    quote bind_quoted: [module: module] do
      @incant_dashboard_chart_opts Keyword.put(
                                     @incant_dashboard_chart_opts || [],
                                     :dataset,
                                     module
                                   )
    end
  end

  defmacro x(field, opts \\ []) do
    quote bind_quoted: [field: field, opts: opts] do
      @incant_dashboard_chart_opts Keyword.put(
                                     @incant_dashboard_chart_opts || [],
                                     :x,
                                     {field, opts}
                                   )
    end
  end

  defmacro y(metric, opts \\ []) do
    quote bind_quoted: [metric: metric, opts: opts] do
      @incant_dashboard_chart_opts Keyword.put(
                                     @incant_dashboard_chart_opts || [],
                                     :y,
                                     {metric, opts}
                                   )
    end
  end

  defmacro series(field, opts \\ []) do
    quote bind_quoted: [field: field, opts: opts] do
      @incant_dashboard_chart_opts Keyword.put(
                                     @incant_dashboard_chart_opts || [],
                                     :series,
                                     {field, opts}
                                   )
    end
  end

  defmacro drilldown(target, opts \\ []) do
    quote bind_quoted: [target: target, opts: opts] do
      @incant_dashboard_chart_opts Keyword.put(
                                     @incant_dashboard_chart_opts || [],
                                     :drilldown,
                                     {target, opts}
                                   )
    end
  end
end
