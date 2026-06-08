defmodule Incant.UI.Regions.Chart do
  @moduledoc """
  Semantic chart specification for dashboard widgets.
  """

  defstruct [
    :id,
    :type,
    :dataset,
    :x,
    :y,
    :series,
    :drilldown,
    :title,
    value: nil,
    opts: []
  ]
end
