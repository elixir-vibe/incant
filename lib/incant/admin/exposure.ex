defmodule Incant.Admin.Exposure do
  @moduledoc false

  alias Incant.Resource.Infer

  def resolve(admin, schema, opts \\ []) when is_atom(schema) and is_list(opts) do
    case conventional_resource(admin.module, schema) do
      {:ok, module} -> Incant.metadata(module)
      :error -> Infer.from_schema(schema, Keyword.merge(admin.opts, opts))
    end
  end

  def conventional_resource(admin_module, schema) do
    candidates(admin_module, schema)
    |> Enum.find(&resource_module?/1)
    |> case do
      nil -> :error
      module -> {:ok, module}
    end
  end

  def candidates(admin_module, schema) do
    admin_parts = Module.split(admin_module)
    schema_parts = Module.split(schema)
    schema_leaf = List.last(schema_parts)
    app_prefix = common_prefix(admin_parts, schema_parts)
    relative_schema_parts = Enum.drop(schema_parts, length(app_prefix))

    [
      Module.concat(admin_parts ++ ["Resources", schema_leaf]),
      Module.concat(admin_parts ++ ["Resources"] ++ relative_schema_parts)
    ]
    |> Enum.uniq()
  end

  defp resource_module?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__incant_resource__, 0)
  end

  defp common_prefix([left | left_rest], [right | right_rest]) when left == right do
    [left | common_prefix(left_rest, right_rest)]
  end

  defp common_prefix(_left, _right), do: []
end
