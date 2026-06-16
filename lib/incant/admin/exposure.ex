defmodule Incant.Admin.Exposure do
  @moduledoc false

  alias Incant.Resource.Infer

  def resolve(admin, schema, opts \\ []) when is_atom(schema) and is_list(opts) do
    case conventional_resource(admin.module, schema, opts) do
      {:ok, module} ->
        module
        |> Incant.metadata()
        |> validate_override_schema!(schema)
        |> merge_exposure_opts(opts)

      :error ->
        Infer.from_schema(schema, Keyword.merge(admin.opts, opts))
    end
  end

  def conventional_resource(admin_module, schema, opts \\ []) do
    candidates(admin_module, schema, opts)
    |> Enum.find(&resource_module?/1)
    |> case do
      nil -> :error
      module -> {:ok, module}
    end
  end

  def candidates(admin_module, schema, opts \\ []) do
    admin_parts = Module.split(admin_module)
    schema_parts = Module.split(schema)
    schema_leaf = List.last(schema_parts)
    app_prefix = common_prefix(admin_parts, schema_parts)
    relative_schema_parts = Enum.drop(schema_parts, length(app_prefix))

    as_candidate =
      opts[:as] &&
        Module.concat(admin_parts ++ ["Resources", opts[:as] |> to_string() |> Macro.camelize()])

    [
      as_candidate,
      Module.concat(admin_parts ++ ["Resources", schema_leaf]),
      Module.concat(admin_parts ++ ["Resources"] ++ relative_schema_parts)
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
  end

  defp validate_override_schema!(%{schema: schema} = metadata, schema), do: metadata

  defp validate_override_schema!(metadata, exposed_schema) do
    raise ArgumentError,
          "conventional Incant resource #{inspect(metadata.module)} has schema #{inspect(metadata.schema)}, expected #{inspect(exposed_schema)}"
  end

  defp merge_exposure_opts(metadata, []), do: metadata

  defp merge_exposure_opts(%{opts: resource_opts} = metadata, opts) do
    opts = Keyword.merge(opts, resource_opts)
    %{metadata | id: opts[:id] || opts[:as] || metadata.id, opts: opts}
  end

  defp resource_module?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__incant_resource__, 0)
  end

  defp common_prefix([left | left_rest], [right | right_rest]) when left == right do
    [left | common_prefix(left_rest, right_rest)]
  end

  defp common_prefix(_left, _right), do: []
end
