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

  defp truthy?(value), do: value not in [nil, false]
end
