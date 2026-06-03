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
  Builds an empty record for a resource form.
  """
  def new_record(%{schema: schema}) when is_atom(schema) and not is_nil(schema) do
    if function_exported?(schema, :__struct__, 0), do: struct(schema), else: %{}
  end

  def new_record(_resource), do: %{}

  @doc """
  Builds a changeset for a resource when a changeset callback is configured.
  """
  def changeset(%{changeset: nil}, _record, _attrs), do: nil

  def changeset(resource, record, attrs) do
    Incant.Callback.call(resource.changeset, record, attrs)
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
