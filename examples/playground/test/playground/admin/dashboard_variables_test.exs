defmodule Playground.Admin.DashboardVariablesTest do
  use ExUnit.Case, async: true

  test "dashboard widget callbacks accept typed and raw variable contexts" do
    dashboard = Incant.metadata(Playground.Admin.Dashboards.LLM)
    widget = Enum.find(dashboard.widgets, &(&1.id == :total_requests))

    variables = %{"range" => %{"from" => ~D[2026-05-01], "to" => ~D[2026-05-31]}}
    raw_variables = %{"range" => %{"from" => "2026-05-01", "to" => "2026-05-31"}}

    assert Incant.Callback.call(widget.opts[:query], variables, %{raw_variables: raw_variables}) == 3
  end
end
