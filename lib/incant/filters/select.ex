defmodule Incant.Filters.Select do
  @moduledoc """
  Single-select filter implementation.
  """

  @behaviour Incant.Filter

  use Phoenix.Component

  import Incant.Live.UI

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
    Shared.apply_query_callback(filter, queryable, value, context)
  end
end
