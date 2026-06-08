defmodule Incant.Dataset do
  @moduledoc """
  Defines a code-first analytical dataset.

  Datasets describe dimensions, metrics, default tables, and drilldowns for
  analytical data sources such as QuackDB, Postgres, or external APIs. They are
  metadata-first; data-source adapters own query execution.
  """

  alias Incant.Dataset.{Dimension, Drilldown, Filter, Metadata, Metric, Table}
  alias Incant.Query
  alias Incant.Result
  alias Incant.Tabular

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

      Module.register_attribute(__MODULE__, :incant_dataset_filters,
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
      filters:
        env.module
        |> Module.get_attribute(:incant_dataset_filters)
        |> Enum.reverse()
        |> Enum.map(fn {name, type, filter_opts, query} ->
          %Filter{name: name, type: type, opts: filter_opts, query: query}
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

  defmacro filters(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro filter(name, type \\ :auto, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      @incant_dataset_filters {name, type, opts, Keyword.get(opts, :query)}
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

  @doc """
  Builds a normalized query request for a dataset.
  """
  def query(dataset_or_module, opts \\ []) do
    dataset = metadata(dataset_or_module)
    table = dataset.table

    %Query{
      source: dataset.source,
      dataset: dataset,
      from: dataset.from,
      dimensions: names(dataset.dimensions),
      metrics: names(dataset.metrics),
      group_by: Keyword.get(opts, :group_by, table.group_by),
      columns: Keyword.get(opts, :columns, table.columns),
      drilldown: Keyword.get(opts, :drilldown),
      filters: Keyword.get(opts, :filters, %{}),
      sort: Keyword.get(opts, :sort, sort_keyword(table.sort)),
      page: Keyword.get(opts, :page),
      page_size: Keyword.get(opts, :page_size),
      variables: Keyword.get(opts, :variables, %{}),
      context: Keyword.get(opts, :context)
    }
  end

  @doc """
  Runs a dataset query through the configured data source.
  """
  def run(dataset_or_module, opts \\ []) do
    dataset_or_module
    |> query(opts)
    |> run_query()
  end

  defp run_query(%Query{source: source} = query) when is_atom(source) and not is_nil(source) do
    if function_exported?(source, :query, 1) do
      source.query(query) |> normalize_source_result()
    else
      {:error, {:missing_query_callback, source}}
    end
  end

  defp run_query(%Query{source: source}), do: {:error, {:invalid_source, source}}

  defp normalize_source_result({:ok, %Result{} = result}), do: {:ok, result}
  defp normalize_source_result({:ok, rows}), do: {:ok, result_from_tabular(rows)}
  defp normalize_source_result({:error, reason}), do: {:error, reason}
  defp normalize_source_result(%Result{} = result), do: {:ok, result}
  defp normalize_source_result(rows), do: {:ok, result_from_tabular(rows)}

  defp result_from_tabular(data) do
    metadata = Tabular.metadata(data)

    %Result{
      rows: Tabular.to_rows(data),
      columns: metadata.columns,
      total_count: metadata.count
    }
  end

  defp metadata(%Metadata{} = dataset), do: dataset
  defp metadata(module) when is_atom(module), do: Incant.metadata(module)

  defp names(records), do: Enum.map(records, & &1.name)
  defp sort_keyword(nil), do: []
  defp sort_keyword({field, direction}), do: [{field, direction}]
  defp sort_keyword(sort), do: sort
end
