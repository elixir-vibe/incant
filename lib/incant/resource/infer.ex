defmodule Incant.Resource.Infer do
  @moduledoc false

  alias Incant.Form
  alias Incant.Form.Field
  alias Incant.Resource.Metadata
  alias Incant.Table
  alias Incant.Table.{Action, Column, Filter}

  @timestamp_fields [:inserted_at, :updated_at]

  def from_schema(schema, opts \\ []) when is_atom(schema) and is_list(opts) do
    Code.ensure_loaded!(schema)

    fields = schema.__schema__(:fields)
    primary_key = schema.__schema__(:primary_key)
    readonly? = Keyword.get(opts, :readonly, false)

    %Metadata{
      module: schema,
      schema: schema,
      repo: Keyword.get(opts, :repo),
      data: Keyword.get(opts, :data) || Keyword.get(opts, :list),
      changeset: Keyword.get(opts, :changeset),
      form: %Form{fields: form_fields(schema, fields, primary_key, readonly?), opts: []},
      table: %Table{
        columns: Enum.map(fields, &column(schema, &1, primary_key)),
        filters: filters(schema, fields),
        actions: actions(readonly?),
        opts: Keyword.take(opts, [:density])
      },
      opts:
        opts |> Keyword.put_new(:title, inferred_title(schema)) |> Keyword.put(:inferred, true)
    }
  end

  defp column(schema, field, primary_key) do
    opts = []
    opts = if field in primary_key, do: Keyword.put(opts, :link, true), else: opts
    opts = opts ++ display_opts(schema.__schema__(:type, field))
    %Column{name: field, opts: opts}
  end

  defp filters(schema, fields) do
    fields
    |> Enum.reject(&(&1 in @timestamp_fields))
    |> Enum.map(fn field ->
      %Filter{
        name: field,
        type: filter_type(schema.__schema__(:type, field)),
        opts: [],
        query: nil
      }
    end)
  end

  defp form_fields(_schema, _fields, _primary_key, true), do: []

  defp form_fields(schema, fields, primary_key, false) do
    fields
    |> Enum.reject(&(&1 in primary_key or &1 in @timestamp_fields))
    |> Enum.map(fn field ->
      %Field{name: field, type: field_type(schema.__schema__(:type, field)), opts: []}
    end)
  end

  defp actions(true), do: []

  defp actions(false) do
    [
      %Action{name: :edit, scope: :row, opts: []},
      %Action{name: :delete, scope: :row, opts: [confirm: true, destructive: true]},
      %Action{name: :new, scope: :page, opts: []}
    ]
  end

  defp filter_type(:boolean), do: :boolean
  defp filter_type(:date), do: :date_range
  defp filter_type(:utc_datetime), do: :date_range
  defp filter_type(:naive_datetime), do: :date_range
  defp filter_type({:parameterized, Ecto.Enum, _opts}), do: :select
  defp filter_type(_type), do: :text

  defp field_type(:boolean), do: :boolean
  defp field_type(:integer), do: :number
  defp field_type(:float), do: :number
  defp field_type(:decimal), do: :number
  defp field_type(:date), do: :date
  defp field_type(:utc_datetime), do: :datetime
  defp field_type(:naive_datetime), do: :datetime
  defp field_type({:parameterized, Ecto.Enum, _opts}), do: :select
  defp field_type(_type), do: :text

  defp display_opts(:integer), do: [format: :number]
  defp display_opts(:float), do: [format: :number]
  defp display_opts(:decimal), do: [format: :number]
  defp display_opts(:boolean), do: [as: :boolean]
  defp display_opts(:date), do: [format: :date]
  defp display_opts(:utc_datetime), do: [format: :datetime]
  defp display_opts(:naive_datetime), do: [format: :datetime]
  defp display_opts(_type), do: []

  defp inferred_title(schema) do
    schema
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> String.replace("_", " ")
    |> String.split()
    |> Enum.map_join(" ", &String.capitalize/1)
  end
end
