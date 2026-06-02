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
      |> Enum.map(fn field -> %Field{name: field, type: schema_type(schema, field), opts: []} end)
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

  defp schema_type(schema, field) do
    case apply(schema, :__schema__, [:type, field]) do
      :integer -> :number
      :float -> :number
      :decimal -> :number
      :boolean -> :boolean
      :date -> :date
      :utc_datetime -> :datetime
      :naive_datetime -> :datetime
      type when is_atom(type) -> type
      _type -> :auto
    end
  end
end
