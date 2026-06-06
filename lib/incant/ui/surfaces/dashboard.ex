defmodule Incant.UI.Surfaces.Dashboard do
  @moduledoc """
  Dashboard surface model.
  """

  alias Incant.UI.Regions.{FilterBar, WidgetGrid}

  defstruct [:id, :title, :dashboard, :variables, :widgets, :layout, regions: [], context: nil]

  def from_context(context, title) do
    variables =
      Enum.map(
        context.dashboard.variables,
        &Incant.UI.Controls.from_dashboard_variable(&1, context)
      )

    widgets = WidgetGrid.from_context(context)

    %__MODULE__{
      id: "dashboard.#{context.dashboard.module}",
      title: title,
      dashboard: context.dashboard,
      variables: variables,
      widgets: widgets.widgets,
      layout: context.dashboard.grid,
      regions: [FilterBar.dashboard_variables(variables), widgets],
      context: context
    }
  end
end
