defmodule Incant.Filters.Select do
  @moduledoc """
  Single-select filter implementation.
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
      options={@filter.opts[:options] || []}
    />
    """
  end

  @impl true
  def match?(_filter, _row, value) when value in [nil, ""], do: true

  def match?(filter, row, value) do
    row
    |> Shared.row_value(filter.name)
    |> to_string()
    |> Kernel.==(to_string(value))
  end

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
