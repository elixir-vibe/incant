defmodule Incant.Sensitive do
  @moduledoc """
  Helpers for secret/sensitive Incant metadata.

  Incant treats `:secret`, `:sensitive`, and `:redacted` as presentation and
  transport-safety hints. They do not replace authorization; they prevent common
  table/detail/contract rendering paths from exposing raw values.
  """

  @redacted "[redacted]"

  @doc "Returns true when metadata opts mark a value as sensitive."
  def sensitive?(opts) when is_list(opts) do
    truthy?(Keyword.get(opts, :secret)) or truthy?(Keyword.get(opts, :sensitive)) or
      truthy?(Keyword.get(opts, :redacted))
  end

  def sensitive?(_opts), do: false

  @doc "Returns a stable redacted display value for sensitive fields."
  def redact(_value), do: @redacted

  @doc "Redacts a value when opts are sensitive; otherwise returns it unchanged."
  def redact(value, opts) do
    if sensitive?(opts), do: redact(value), else: value
  end

  @doc "Redacts sensitive fields from a row according to resource column metadata."
  def redact_row(row, %{table: %{columns: columns}}) when is_map(row) do
    Enum.reduce(columns, row, fn column, acc ->
      if sensitive?(column.opts) do
        redact_field(acc, column.name)
      else
        acc
      end
    end)
  end

  def redact_row(row, _resource), do: row

  defp redact_field(%_struct{} = row, field), do: Map.put(row, field, @redacted)

  defp redact_field(row, field) when is_map(row) do
    row
    |> maybe_put_redacted(field)
    |> maybe_put_redacted(to_string(field))
  end

  defp maybe_put_redacted(row, field) do
    if Map.has_key?(row, field), do: Map.put(row, field, @redacted), else: row
  end

  defp truthy?(value), do: value not in [nil, false]
end
