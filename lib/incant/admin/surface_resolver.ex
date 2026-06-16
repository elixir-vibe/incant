defmodule Incant.Admin.SurfaceResolver do
  @moduledoc false

  alias Incant.Surface

  def surfaces(admin_or_metadata) do
    admin = metadata(admin_or_metadata)

    resources(admin) ++ dashboards(admin) ++ datasets(admin)
  end

  def resources(admin_or_metadata) do
    admin = metadata(admin_or_metadata)

    explicit =
      Enum.map(admin.resources, fn module ->
        module
        |> Incant.metadata()
        |> resource_surface()
      end)

    exposed =
      Enum.map(admin.exposed, fn {schema, opts} ->
        admin
        |> Incant.Admin.Exposure.resolve(schema, opts)
        |> resource_surface()
      end)

    explicit ++ exposed
  end

  def dashboards(admin_or_metadata) do
    admin_or_metadata
    |> metadata()
    |> Map.fetch!(:dashboards)
    |> Enum.map(fn module ->
      module
      |> Incant.metadata()
      |> dashboard_surface()
    end)
  end

  def datasets(admin_or_metadata) do
    admin_or_metadata
    |> metadata()
    |> Map.fetch!(:datasets)
    |> Enum.map(fn module ->
      module
      |> Incant.metadata()
      |> dataset_surface()
    end)
  end

  defp metadata(%Incant.Admin.Metadata{} = metadata), do: metadata
  defp metadata(module) when is_atom(module), do: Incant.metadata(module)

  defp resource_surface(resource) do
    %Surface{
      kind: :resource,
      id: resource_id!(resource),
      module: resource.module,
      title: Surface.title(resource.module, resource.opts),
      spec: resource,
      opts: resource.opts
    }
  end

  defp dashboard_surface(dashboard) do
    %Surface{
      kind: :dashboard,
      id: Surface.id(dashboard.module, dashboard.opts),
      module: dashboard.module,
      title: Surface.title(dashboard.module, dashboard.opts, dashboard.title),
      spec: dashboard,
      opts: dashboard.opts
    }
  end

  defp dataset_surface(dataset) do
    %Surface{
      kind: :dataset,
      id: Surface.id(dataset.module, dataset.opts),
      module: dataset.module,
      title: Surface.title(dataset.module, dataset.opts, dataset.title),
      spec: dataset,
      opts: dataset.opts
    }
  end

  defp resource_id!(%{id: id}) when is_binary(id), do: id
  defp resource_id!(%{id: id}) when is_atom(id), do: to_string(id)

  defp resource_id!(resource) do
    raise ArgumentError,
          "Incant resource metadata must include an explicit id, got: #{inspect(resource)}"
  end
end
