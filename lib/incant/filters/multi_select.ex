defmodule Incant.Filters.MultiSelect do
  @moduledoc """
  Multi-select filter implementation.
  """

  @behaviour Incant.Filter

  use Phoenix.Component

  import Ecto.Query
  import Incant.Live.Components

  alias Incant.Filters.Shared

  @impl true
  def control(filter, value, _assigns) do
    assigns = %{filter: filter, value: value}

    ~H"""
    <.select
      name={"table[filters][#{@filter.name}][]"}
      value={@value}
      options={@filter.opts[:options] || []}
      multiple
      class="min-h-24"
    />
    """
  end

  @impl true
  def match?(_filter, _row, value) when value in [nil, "", []], do: true

  def match?(filter, row, values) do
    values = values |> List.wrap() |> Enum.reject(&(&1 in [nil, ""])) |> Enum.map(&to_string/1)
    values == [] or (row |> Shared.row_value(filter.name) |> to_string()) in values
  end

  @impl true
  def apply_query(filter, queryable, value, context) do
    values = value |> List.wrap() |> Enum.reject(&(&1 in [nil, ""]))

    if Shared.custom_query?(filter) or values == [] do
      Shared.apply_query_callback(filter, queryable, value, context)
    else
      where(queryable, [row], field(row, ^filter.name) in ^values)
    end
  rescue
    _error -> queryable
  end
end
