defmodule Incant.Filters.Boolean do
  @moduledoc """
  Boolean filter implementation.
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
      name={"table[filters][#{@filter.name}]"}
      value={@value}
      prompt={"#{@filter.name}"}
      options={[{"Yes", "true"}, {"No", "false"}]}
    />
    """
  end

  @impl true
  def match?(_filter, _row, value) when value in [nil, ""], do: true

  def match?(filter, row, "true"),
    do: Shared.row_value(row, filter.name) in [true, "true", 1, "1"]

  def match?(filter, row, "false"),
    do: Shared.row_value(row, filter.name) in [false, "false", 0, "0"]

  def match?(_filter, _row, _value), do: true

  @impl true
  def apply_query(filter, queryable, value, context) do
    if Shared.custom_query?(filter) or Shared.blank?(value) do
      Shared.apply_query_callback(filter, queryable, value, context)
    else
      where(
        queryable,
        [row],
        field(row, ^filter.name) == ^Shared.cast_query_value(filter, value, context)
      )
    end
  rescue
    _error -> queryable
  end
end
