defmodule Incant.UI.Regions.FilterBar do
  @moduledoc """
  Search and filter controls for a resource or dashboard variables surface.
  """

  defstruct [:id, :search, filters: [], saved_views: [], density: :compact, events: %{}]

  def from_context(%{resource: resource, table_state: table_state} = context) do
    search =
      if resource.table.search do
        %Incant.UI.Controls.Text{
          id: "table.search",
          name: "search",
          label: "Search",
          role: :search,
          value: table_state.search,
          placeholder: "Search",
          commit: :change
        }
      end

    filters =
      Enum.map(resource.table.filters, fn filter ->
        value = Map.get(table_state.filters, to_string(filter.name), "")
        Incant.UI.Controls.from_table_filter(filter, value, context)
      end)

    %__MODULE__{id: "resource.filters", search: search, filters: filters}
  end

  def from_dataset_context(%{dataset: dataset, table_state: table_state} = context) do
    filters =
      Enum.map(dataset.filters, fn filter ->
        value = Map.get(table_state.filters, to_string(filter.name), "")
        Incant.UI.Controls.from_table_filter(filter, value, context)
      end)

    %__MODULE__{id: "dataset.filters", filters: filters}
  end

  def dashboard_variables(variables) do
    %__MODULE__{id: "dashboard.variables", filters: variables}
  end
end
