defmodule Incant.Admin.Describe do
  @moduledoc false

  alias Incant.Admin.Contract

  @public_opts %{
    admin: [:service, :version],
    resource: [:id, :as, :title, :readonly, :inferred],
    table: [:density],
    form: [:layout],
    dashboard: [:id, :as, :title],
    dataset: [:id, :as, :title],
    dataset_table: [:density],
    grid: [:columns, :row_height],
    named: [
      :id,
      :label,
      :format,
      :as,
      :align,
      :width,
      :priority,
      :tone,
      :link,
      :sortable,
      :sensitive,
      :secret,
      :redacted
    ],
    typed: [:id, :label, :default, :options],
    field: [
      :id,
      :label,
      :placeholder,
      :required,
      :readonly,
      :options,
      :sensitive,
      :secret,
      :redacted
    ],
    filter: [:id, :label, :placeholder, :options],
    action: [:id, :label, :confirm, :destructive, :async, :result],
    widget: [:id, :label, :span, :format, :chart_type, :x, :y, :series, :drilldown],
    metric: [:id, :label, :format],
    drilldown: [:group_by, :columns, :label],
    row_detail: [:id, :label, :kind, :type]
  }

  def describe(admin_or_metadata) do
    admin = metadata(admin_or_metadata)
    opts = public_opts(admin.opts, :admin)
    service = Map.get(opts, :service)

    %Contract{
      id: to_string(service || module_id(admin.module)),
      module: inspect(admin.module),
      service: service,
      version: Map.get(opts, :version),
      resources: admin |> Incant.Admin.resources() |> Enum.map(&describe_resource_surface/1),
      dashboards: admin |> Incant.Admin.dashboards() |> Enum.map(&describe_dashboard_surface/1),
      datasets: admin |> Incant.Admin.datasets() |> Enum.map(&describe_dataset_surface/1),
      plugins: Enum.map(admin.plugins, &inspect/1),
      opts: opts
    }
  end

  defp metadata(%Incant.Admin.Metadata{} = metadata), do: metadata
  defp metadata(module) when is_atom(module), do: Incant.metadata(module)

  defp describe_resource_surface(%Incant.Surface{kind: :resource, spec: resource} = surface) do
    %{
      id: surface.id,
      kind: :resource,
      module: inspect(surface.module),
      title: surface.title,
      table: %{
        columns: Enum.map(resource.table.columns, &describe_named_opts/1),
        filters: Enum.map(resource.table.filters, &describe_resource_filter/1),
        actions: Enum.map(resource.table.actions, &describe_action/1),
        bulk_actions: Enum.map(resource.table.bulk_actions, &describe_action/1),
        page_actions: Enum.map(resource.table.page_actions, &describe_action/1),
        row_detail: describe_row_detail(resource.table.row_detail),
        search: public_value(resource.table.search),
        opts: public_opts(resource.table.opts, :table)
      },
      form: %{
        fields: Enum.map(resource.form.fields, &describe_field/1),
        opts: public_opts(resource.form.opts, :form)
      },
      opts: public_opts(resource.opts, :resource)
    }
  end

  defp describe_dashboard_surface(%Incant.Surface{kind: :dashboard, spec: dashboard} = surface) do
    %{
      id: surface.id,
      kind: :dashboard,
      module: inspect(surface.module),
      title: surface.title,
      variables: Enum.map(dashboard.variables, &describe_typed_opts/1),
      widgets: Enum.map(dashboard.widgets, &describe_widget/1),
      grid: public_opts(dashboard.grid, :grid),
      opts: public_opts(dashboard.opts, :dashboard)
    }
  end

  defp describe_dataset_surface(%Incant.Surface{kind: :dataset, spec: dataset} = surface) do
    %{
      id: surface.id,
      kind: :dataset,
      module: inspect(surface.module),
      title: surface.title,
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
        opts: public_opts(dataset.table.opts, :dataset_table)
      },
      opts: public_opts(dataset.opts, :dataset)
    }
  end

  defp describe_named_opts(%{name: name, opts: opts}) do
    %{id: to_string(name), name: public_value(name), opts: public_opts(opts, :named)}
  end

  defp describe_typed_opts(opts), do: describe_named_typed_opts(opts, :typed)
  defp describe_field(field), do: describe_named_typed_opts(field, :field)
  defp describe_resource_filter(filter), do: describe_named_typed_opts(filter, :filter)
  defp describe_dataset_filter(filter), do: describe_named_typed_opts(filter, :filter)

  defp describe_named_typed_opts(%{name: name, type: type, opts: opts}, kind) do
    %{
      id: to_string(name),
      name: public_value(name),
      type: public_value(type),
      opts: public_opts(opts, kind)
    }
  end

  defp describe_action(%{name: name, scope: scope, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      scope: public_value(scope),
      opts: public_opts(opts, :action)
    }
  end

  defp describe_widget(%{id: id, type: type, opts: opts}) do
    %{id: to_string(id), type: public_value(type), opts: public_opts(opts, :widget)}
  end

  defp describe_metric(%{name: name, aggregate: aggregate, expr: expr, opts: opts}) do
    %{
      id: to_string(name),
      name: public_value(name),
      aggregate: public_value(aggregate),
      expr: public_value(expr),
      opts: public_opts(opts, :metric)
    }
  end

  defp describe_drilldown(%{dimension: dimension, opts: opts}) do
    %{dimension: public_value(dimension), opts: public_opts(opts, :drilldown)}
  end

  defp describe_row_detail(nil), do: nil

  defp describe_row_detail({name, opts}),
    do: %{id: to_string(name), name: public_value(name), opts: public_opts(opts, :row_detail)}

  defp public_opts(opts, scope) when is_list(opts) do
    allowed = Map.fetch!(@public_opts, scope)

    opts
    |> Keyword.take(allowed)
    |> Map.new(fn {key, value} -> {key, public_value(value)} end)
  end

  defp public_opts(%{} = map, scope), do: map |> Map.to_list() |> public_opts(scope)
  defp public_opts(_other, _scope), do: %{}

  defp public_value(value)
       when is_binary(value) or is_number(value) or is_boolean(value) or is_nil(value),
       do: value

  defp public_value(value) when is_atom(value) do
    if module_atom?(value) do
      raise ArgumentError,
            "module atoms are not portable Incant contract values: #{inspect(value)}"
    else
      value
    end
  end

  defp public_value(values) when is_list(values), do: Enum.map(values, &public_value/1)

  defp public_value(%{} = map),
    do: Map.new(map, fn {key, value} -> {public_value(key), public_value(value)} end)

  defp public_value({left, right}), do: [public_value(left), public_value(right)]

  defp public_value(value) when is_function(value) do
    raise ArgumentError, "functions are not portable Incant contract values: #{inspect(value)}"
  end

  defp public_value(value) do
    raise ArgumentError, "unsupported Incant contract value: #{inspect(value)}"
  end

  defp module_atom?(value) do
    value |> Atom.to_string() |> String.starts_with?("Elixir.")
  end

  defp module_id(module), do: module |> Module.split() |> Enum.map_join(".", &Macro.underscore/1)
end
