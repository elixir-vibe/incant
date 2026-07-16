defmodule Incant.Table.Action do
  @moduledoc """
  Metadata for a table action.

  Actions are semantic commands. A table can expose row actions, bulk actions,
  and page actions; adapters decide whether they render as buttons, menus,
  command palettes, drawers, or other UI primitives.
  """

  @type scope :: :row | :bulk | :page

  @type t :: %__MODULE__{
          name: atom,
          scope: scope,
          opts: keyword
        }

  defstruct [:name, scope: :row, opts: []]

  @doc "Returns whether a row action currently applies to a row."
  @spec available?(t(), term(), map()) :: boolean()
  def available?(%__MODULE__{opts: opts}, row, context \\ %{}) do
    case option(opts, :available_if) do
      nil -> true
      conditions when is_list(conditions) -> matches?(row, conditions)
      conditions when is_map(conditions) -> matches?(row, conditions)
      callback -> Incant.Callback.call(callback, row, context) == true
    end
  rescue
    _error in [ArgumentError, FunctionClauseError, UndefinedFunctionError] -> false
  end

  defp matches?(row, conditions) do
    Enum.all?(conditions, fn {field, expected} ->
      Incant.Live.Rows.field(row, field) == expected
    end)
  end

  defp option(opts, key) when is_list(opts), do: Keyword.get(opts, key)
  defp option(opts, key) when is_map(opts), do: Map.get(opts, key, Map.get(opts, to_string(key)))
  defp option(_opts, _key), do: nil
end
