defmodule Incant.Live.Routes do
  @moduledoc false

  def dashboard_path(base_path, dashboard, query_params \\ %{}) do
    path([base_path, "dashboards", surface_id(dashboard)], query_params)
  end

  def dataset_path(base_path, dataset, query_params \\ %{}) do
    path([base_path, "datasets", surface_id(dataset)], query_params)
  end

  def resource_path(base_path, resource, query_params \\ %{}) do
    path([base_path, "resources", surface_id(resource)], query_params)
  end

  def resource_new_path(base_path, resource, query_params \\ %{}) do
    path([base_path, "resources", surface_id(resource), "new"], query_params)
  end

  def resource_detail_path(base_path, resource, id, query_params \\ %{}) do
    path([base_path, "resources", surface_id(resource), id], query_params)
  end

  def resource_edit_path(base_path, resource, id, query_params \\ %{}) do
    path([base_path, "resources", surface_id(resource), id, "edit"], query_params)
  end

  def current_path(%{context: context, params: params}, query_params) do
    current_path(context, params, query_params)
  end

  def current_path(%{section: "resource"} = context, params, query_params) do
    cond do
      context.form_mode == :edit && context.detail_id ->
        resource_edit_path(context.base_path, context.resource, context.detail_id, query_params)

      params["id"] ->
        resource_detail_path(context.base_path, context.resource, params["id"], query_params)

      true ->
        resource_path(context.base_path, context.resource, query_params)
    end
  end

  def current_path(%{section: "dashboard"} = context, _params, query_params) do
    dashboard_path(context.base_path, context.dashboard, query_params)
  end

  def current_path(%{section: "dataset"} = context, _params, query_params) do
    dataset_path(context.base_path, context.dataset, query_params)
  end

  def surface_id(%Incant.Resource.Metadata{id: id}), do: id

  def surface_id(%Incant.Dashboard.Metadata{} = dashboard),
    do: Incant.Surface.id(dashboard.module, dashboard.opts)

  def surface_id(%Incant.Dataset.Metadata{} = dataset),
    do: Incant.Surface.id(dataset.module, dataset.opts)

  def surface_id(%Incant.Surface{id: id}), do: id
  def surface_id(%{id: id}), do: id

  defp path([base_path | segments], query_params) do
    suffix =
      Enum.map_join(segments, "/", fn segment ->
        URI.encode(to_string(segment), &URI.char_unreserved?/1)
      end)

    path = base_path <> "/" <> suffix
    query_params = reject_empty_values(query_params)

    case encode_query(query_params) do
      "" -> path
      query -> path <> "?" <> query
    end
  end

  defp encode_query(query_params) do
    query_params
    |> query_pairs()
    |> URI.encode_query()
  end

  defp query_pairs(map) when is_map(map) do
    Enum.flat_map(map, fn
      {key, value} when is_map(value) ->
        value
        |> reject_empty_values()
        |> Enum.flat_map(fn {nested_key, nested_value} ->
          query_value_pairs("#{key}[#{nested_key}]", nested_value)
        end)

      {key, value} ->
        query_value_pairs(key, value)
    end)
  end

  defp query_value_pairs(key, values) when is_list(values),
    do: Enum.map(values, &{"#{key}[]", &1})

  defp query_value_pairs(key, value), do: [{key, value}]

  defp reject_empty_values(map) do
    Map.reject(map, fn {_key, value} -> value in [nil, "", %{}] end)
  end
end
