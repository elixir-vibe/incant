defmodule Incant.Admin.Describe do
  @moduledoc false

  alias Incant.Admin.Contract

  def describe(admin_or_metadata) do
    admin = metadata(admin_or_metadata)
    opts = public_opts(admin.opts)
    service = Map.get(opts, :service)

    %Contract{
      id: to_string(service || module_id(admin.module)),
      module: inspect(admin.module),
      service: service,
      version: Map.get(opts, :version),
      resources: Enum.map(admin.resources, &describe_resource/1),
      dashboards: Enum.map(admin.dashboards, &describe_dashboard/1),
      datasets: Enum.map(admin.datasets, &describe_dataset/1),
      plugins: Enum.map(admin.plugins, &inspect/1),
      opts: opts
    }
  end

  defp metadata(%Incant.Admin.Metadata{} = metadata), do: metadata
  defp metadata(module) when is_atom(module), do: Incant.metadata(module)

  defp describe_resource(module) do
    resource = Incant.metadata(module)

    %{
      id: surface_id(resource.module),
      kind: :resource,
      module: inspect(resource.module),
      title: title(resource.module, resource.opts),
      table: %{
        columns: Enum.map(resource.table.columns, &describe_named_opts/1),
        filters: Enum.map(resource.table.filters, &describe_resource_filter/1),
        actions: Enum.map(resource.table.actions, &describe_action/1),
        bulk_actions: Enum.map(resource.table.bulk_actions, &describe_action/1),
        page_actions: Enum.map(resource.table.page_actions, &describe_action/1),
        row_detail: describe_row_detail(resource.table.row_detail),
        search: public_value(resource.table.search),
        opts: public_opts(resource.table.opts)
      },
      form: %{
        fields: Enum.map(resource.form.fields, &describe_field/1),
        opts: public_opts(resource.form.opts)
      },
      opts: public_opts(resource.opts)
    }
  end

  defp describe_dashboard(module) do
    dashboard = Incant.metadata(module)

    %{
      id: surface_id(dashboard.module),
      kind: :dashboard,
      module: inspect(dashboard.module),
      title: dashboard.title || title(dashboard.module, dashboard.opts),
      variables: Enum.map(dashboard.variables, &describe_typed_opts/1),
      widgets: Enum.map(dashboard.widgets, &describe_widget/1),
      grid: public_opts(dashboard.grid),
      opts: public_opts(dashboard.opts)
    }
  end

  defp describe_dataset(module) do
    dataset = Incant.metadata(module)

    %{
      id: surface_id(dataset.module),
      kind: :dataset,
      module: inspect(dataset.module),
      title: dataset.title || title(dataset.module, dataset.opts),
      from: public_value(dataset.from),
      dimensions: Enum.map(dataset.dimensions, &describe_named_opts/1),
      metrics: Enum.map(dataset.metrics, &describe_metric/1),
      filters: Enum.map(dataset.filters, &describe_dataset_filter/1),
      table: %{
        group_by: Enum.map(dataset.table.group_by, &public_value/1),
        columns: Enum.map(dataset.table.columns, &public_value/1),
        sort: public_value(dataset.table.sort),
        heatmap: Enum.map(dataset.table.heatmap, &public_value/1),
        drilldowns: Enum.map(dataset.table.drilldowns, &describe_drilldown/1),
        opts: public_opts(dataset.table.opts)
      },
      opts: public_opts(dataset.opts)
    }
  end

  defp describe_named_opts(%{name: name, opts: opts}) do
    %{id: to_string(name), name: public_value(name), opts: public_opts(opts)}
  end

  defp describe_typed_opts(%{name: name, type: type, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      type: public_value(type),
      opts: public_opts(opts)
    }
  end

  defp describe_field(%{name: name, type: type, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      type: public_value(type),
      opts: public_opts(opts)
    }
  end

  defp describe_resource_filter(%{name: name, type: type, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      type: public_value(type),
      opts: public_opts(opts)
    }
  end

  defp describe_dataset_filter(%{name: name, type: type, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      type: public_value(type),
      opts: public_opts(opts)
    }
  end

  defp describe_action(%{name: name, scope: scope, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      scope: public_value(scope),
      opts: public_opts(opts)
    }
  end

  defp describe_widget(%{id: id, type: type, opts: opts}) do
    %{id: to_string(id), type: public_value(type), opts: public_opts(opts)}
  end

  defp describe_metric(%{name: name, aggregate: aggregate, expr: expr, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      aggregate: public_value(aggregate),
      expr: public_value(expr),
      opts: public_opts(opts)
    }
  end

  defp describe_drilldown(%{dimension: dimension, opts: opts}) do
    %{dimension: public_value(dimension), opts: public_opts(opts)}
  end

  defp describe_row_detail(nil), do: nil

  defp describe_row_detail({name, opts}),
    do: %{id: to_string(name), name: public_value(name), opts: public_opts(opts)}

  defp public_opts(opts) when is_list(opts) do
    opts
    |> Enum.reject(fn {key, value} -> key in [:repo, :schema, :source] or executable?(value) end)
    |> Map.new(fn {key, value} -> {key, public_value(value)} end)
  end

  defp public_opts(%{} = map) do
    Map.new(map, fn {key, value} -> {key, public_value(value)} end)
  end

  defp public_opts(_other), do: %{}

  defp public_value(value)
       when is_atom(value) or is_binary(value) or is_number(value) or is_boolean(value) or
              is_nil(value),
       do: value

  defp public_value(values) when is_list(values), do: Enum.map(values, &public_value/1)

  defp public_value(%{} = map),
    do: Map.new(map, fn {key, value} -> {public_value(key), public_value(value)} end)

  defp public_value({left, right}), do: [public_value(left), public_value(right)]
  defp public_value(value) when is_function(value), do: nil
  defp public_value(value), do: inspect(value)

  defp executable?(value), do: is_function(value)

  defp title(module, opts), do: opts[:title] || module |> Module.split() |> List.last()

  defp surface_id(module) do
    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp module_id(module), do: module |> Module.split() |> Enum.map_join(".", &Macro.underscore/1)
end
