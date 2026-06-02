defmodule Incant.Filter do
  @moduledoc """
  Behaviour and dispatcher for Incant table filters.
  """

  alias Incant.Table.Filter

  @type context :: term
  @type queryable :: term
  @type row :: map
  @type value :: term

  @callback control(Filter.t(), value, map) :: Phoenix.LiveView.Rendered.t()
  @callback match?(Filter.t(), row, value) :: boolean
  @callback apply_query(Filter.t(), queryable, value, context) :: queryable

  @builtins %{
    auto: Incant.Filters.Text,
    text: Incant.Filters.Text,
    select: Incant.Filters.Select,
    multi_select: Incant.Filters.MultiSelect,
    date_range: Incant.Filters.DateRange,
    boolean: Incant.Filters.Boolean,
    transformer: Incant.Filters.Text
  }

  @doc """
  Resolves the module responsible for a filter.
  """
  def module(%Filter{opts: opts, type: type}) do
    Keyword.get(opts, :filter, Map.get(@builtins, type, Incant.Filters.Text))
  end

  @doc """
  Renders a filter control.
  """
  def control(%Filter{} = filter, value, assigns) do
    filter |> module() |> apply(:control, [filter, value, assigns])
  end

  @doc """
  Returns whether an in-memory row matches a filter value.
  """
  def match?(%Filter{} = filter, row, value) do
    filter |> module() |> apply(:match?, [filter, row, value])
  end

  @doc """
  Applies a filter value to a queryable.
  """
  def apply_query(%Filter{} = filter, queryable, value, context) do
    filter |> module() |> apply(:apply_query, [filter, queryable, value, context])
  end

  @doc """
  Applies a list of filters to a queryable using submitted filter values.
  """
  def apply_filters(filters, queryable, values, context \\ nil) do
    Enum.reduce(filters, queryable, fn filter, queryable ->
      apply_query(filter, queryable, Map.get(values, to_string(filter.name)), context)
    end)
  end
end
