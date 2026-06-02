defmodule Incant.Filters.Text do
  @moduledoc """
  Text filter implementation.
  """

  @behaviour Incant.Filter

  use Phoenix.Component

  import Incant.Live.UI

  alias Incant.Filters.Shared

  @impl true
  def control(filter, value, _assigns) do
    assigns = %{filter: filter, value: value}

    ~H"""
    <.text_input
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
    Shared.apply_query_callback(filter, queryable, value, context)
  end
end
