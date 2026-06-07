defmodule Incant.Dataset do
  @moduledoc """
  Defines a code-first analytical dataset.

  Datasets describe dimensions, metrics, default tables, and drilldowns for
  analytical data sources such as QuackDB, Postgres, or external APIs. They are
  metadata-first; data-source adapters own query execution.
  """

  alias Incant.Dataset.{Dimension, Drilldown, Metadata, Metric, Table}

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Incant.Dataset

      Module.register_attribute(__MODULE__, :incant_dataset_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_dataset_title, persist: false)
      Module.register_attribute(__MODULE__, :incant_dataset_from, persist: false)

      Module.register_attribute(__MODULE__, :incant_dataset_dimensions,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_dataset_metrics,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_dataset_table_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_dataset_group_by, persist: false)
      Module.register_attribute(__MODULE__, :incant_dataset_columns, persist: false)
      Module.register_attribute(__MODULE__, :incant_dataset_sort, persist: false)
      Module.register_attribute(__MODULE__, :incant_dataset_heatmap, persist: false)

      Module.register_attribute(__MODULE__, :incant_dataset_drilldowns,
        accumulate: true,
        persist: false
      )

      @incant_dataset_opts opts
      @before_compile Incant.Dataset
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :incant_dataset_opts) || []

    table = %Table{
      group_by: Module.get_attribute(env.module, :incant_dataset_group_by) || [],
      columns: Module.get_attribute(env.module, :incant_dataset_columns) || [],
      sort: Module.get_attribute(env.module, :incant_dataset_sort),
      heatmap: Module.get_attribute(env.module, :incant_dataset_heatmap) || [],
      drilldowns:
        env.module
        |> Module.get_attribute(:incant_dataset_drilldowns)
        |> Enum.reverse()
        |> Enum.map(fn {dimension, drilldown_opts} ->
          %Drilldown{dimension: dimension, opts: drilldown_opts}
        end),
      opts: Module.get_attribute(env.module, :incant_dataset_table_opts) || []
    }

    metadata = %Metadata{
      module: env.module,
      source: Keyword.get(opts, :source),
      title: Module.get_attribute(env.module, :incant_dataset_title),
      from: Module.get_attribute(env.module, :incant_dataset_from),
      dimensions:
        env.module
        |> Module.get_attribute(:incant_dataset_dimensions)
        |> Enum.reverse()
        |> Enum.map(fn {name, dimension_opts} -> %Dimension{name: name, opts: dimension_opts} end),
      metrics:
        env.module
        |> Module.get_attribute(:incant_dataset_metrics)
        |> Enum.reverse()
        |> Enum.map(fn {name, aggregate, expr, metric_opts} ->
          %Metric{name: name, aggregate: aggregate, expr: expr, opts: metric_opts}
        end),
      table: table,
      opts: opts
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_dataset__, do: unquote(escaped)
    end
  end

  defmacro title(value) do
    quote bind_quoted: [value: value] do
      @incant_dataset_title value
    end
  end

  defmacro from(value) do
    quote bind_quoted: [value: value] do
      @incant_dataset_from value
    end
  end

  defmacro dimensions(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro dimension(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_dataset_dimensions {name, opts}
    end
  end

  defmacro metrics(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro metric(name, aggregate \\ nil, opts \\ []) do
    quote bind_quoted: [name: name, aggregate: aggregate, opts: opts] do
      {aggregate, opts} = normalize_metric_definition(aggregate, opts)

      @incant_dataset_metrics {name, aggregate, Keyword.get(opts, :expr),
                               Keyword.delete(opts, :expr)}
    end
  end

  defmacro table(opts \\ [], do: block) do
    quote do
      @incant_dataset_table_opts unquote(opts)
      unquote(block)
    end
  end

  defmacro group_by(dimensions) do
    quote bind_quoted: [dimensions: dimensions] do
      @incant_dataset_group_by List.wrap(dimensions)
    end
  end

  defmacro columns(columns) do
    quote bind_quoted: [columns: columns] do
      @incant_dataset_columns List.wrap(columns)
    end
  end

  defmacro sort(metric, direction \\ :asc) do
    quote bind_quoted: [metric: metric, direction: direction] do
      @incant_dataset_sort {metric, direction}
    end
  end

  defmacro heatmap(columns) do
    quote bind_quoted: [columns: columns] do
      @incant_dataset_heatmap List.wrap(columns)
    end
  end

  defmacro drilldown(dimension, opts \\ []) do
    quote bind_quoted: [dimension: dimension, opts: opts] do
      @incant_dataset_drilldowns {dimension, opts}
    end
  end

  def normalize_metric_definition(aggregate, opts) when is_list(aggregate) and opts == [] do
    {Keyword.get(aggregate, :aggregate), aggregate}
  end

  def normalize_metric_definition(aggregate, opts), do: {aggregate, opts}
end
