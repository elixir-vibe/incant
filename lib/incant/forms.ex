defmodule Incant.Forms do
  @moduledoc """
  Helpers for resolving resource form fields and changesets.
  """

  alias Incant.Form.Field

  @excluded_schema_fields [:id, :inserted_at, :updated_at]

  @doc """
  Returns explicit form fields, or inferred Ecto schema fields when no form DSL was declared.
  """
  def fields(%{form: %{fields: [_ | _] = fields}}), do: fields

  def fields(%{schema: schema}) when is_atom(schema) and not is_nil(schema) do
    if function_exported?(schema, :__schema__, 1) do
      schema
      |> apply(:__schema__, [:fields])
      |> Enum.reject(&(&1 in @excluded_schema_fields))
      |> Enum.map(fn field -> schema_field(schema, field) end)
    else
      []
    end
  end

  def fields(_resource), do: []

  @doc """
  Resolves the concrete resource metadata used for form fields, records, and
  changesets.

  Local sessions render portable surface maps that lack the repo, changeset
  callback, and schema needed by forms, so resolve the real metadata from the
  local admin's declared resources. Returns `nil` when the resource is not
  form-capable.
  """
  def source_resource(%{kind: :resource} = surface, %{admin: admin}) do
    resolve_local_resource(admin, surface) || nil
  end

  def source_resource(resource, _context) do
    if fields(resource) != [], do: resource
  end

  defp resolve_local_resource(nil, _surface), do: nil

  defp resolve_local_resource(admin, %{module: module}) do
    admin
    |> local_resource_modules()
    |> Enum.find_value(fn resource_module ->
      if inspect(resource_module) == to_string(module) or
           Atom.to_string(resource_module) == to_string(module) do
        Incant.metadata(resource_module)
      end
    end)
  end

  defp resolve_local_resource(_admin, _surface), do: nil

  defp local_resource_modules(%{resources: resources, exposed: exposed}) do
    resources ++ Enum.map(exposed, &elem(&1, 0))
  end

  defp local_resource_modules(_admin), do: []

  @doc """
  Builds an empty record for a resource form.
  """
  def new_record(%{schema: schema}) when is_atom(schema) and not is_nil(schema) do
    if function_exported?(schema, :__struct__, 0), do: struct(schema), else: %{}
  end

  def new_record(_resource), do: %{}

  @doc """
  Builds a changeset for a resource when a changeset callback is configured.
  """
  def changeset(resource, record, attrs) do
    case Map.get(resource, :changeset) do
      nil -> nil
      callback -> Incant.Callback.call(callback, record, attrs)
    end
  end

  defp schema_field(schema, field) do
    case apply(schema, :__schema__, [:type, field]) do
      {:parameterized, {Ecto.Enum, %{mappings: mappings}}} ->
        %Field{name: field, type: :select, opts: [options: Keyword.keys(mappings)]}

      type ->
        %Field{name: field, type: schema_type(type), opts: []}
    end
  end

  defp schema_type(:integer), do: :number
  defp schema_type(:float), do: :number
  defp schema_type(:decimal), do: :number
  defp schema_type(:boolean), do: :boolean
  defp schema_type(:date), do: :date
  defp schema_type(:time), do: :time
  defp schema_type(:utc_datetime), do: :datetime
  defp schema_type(:utc_datetime_usec), do: :datetime
  defp schema_type(:naive_datetime), do: :datetime
  defp schema_type(:naive_datetime_usec), do: :datetime
  defp schema_type(type) when is_atom(type), do: type
  defp schema_type(_type), do: :auto
end
