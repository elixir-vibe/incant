defmodule Incant.Filters.Text do
  @moduledoc """
  Text filter implementation.
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
    <.input
      type="text"
      name={"table[filters][#{@filter.name}]"}
      value={@value}
      placeholder={"#{@filter.name} (#{@filter.type})"}
    />
    """
  end

  @impl true
  def match?(_filter, _row, value) when value in [nil, ""], do: true

  def match?(filter, row, value) do
    row
    |> Shared.row_value(filter.name)
    |> to_string()
    |> String.contains?(to_string(value))
  end

  @impl true
  def apply_query(filter, queryable, value, context) do
    if Shared.custom_query?(filter) or Shared.blank?(value) do
      Shared.apply_query_callback(filter, queryable, value, context)
    else
      pattern = "%#{value}%"

      where(
        queryable,
        [row],
        fragment("lower(?) LIKE lower(?)", field(row, ^filter.name), ^pattern)
      )
    end
  rescue
    _error in [ArgumentError, Ecto.QueryError] -> queryable
  end
end
