defmodule Incant.Live.FormValues do
  @moduledoc false

  def value(%{changes: changes}, record, field) when is_map(changes) do
    Map.get(changes, field, Incant.Live.Rows.field(record, field))
  end

  def value(_changeset, record, field), do: Incant.Live.Rows.field(record, field)

  def errors(%{action: nil}, _field), do: []

  def errors(%{errors: errors}, field) when is_list(errors) do
    errors
    |> Keyword.get_values(field)
    |> Enum.map(fn
      {message, opts} -> interpolate_error(message, opts)
      message -> to_string(message)
    end)
  end

  def errors(_changeset, _field), do: []

  defp interpolate_error(message, opts) do
    Enum.reduce(opts, message, fn {key, value}, message ->
      String.replace(message, "%{#{key}}", to_string(value))
    end)
  end
end
