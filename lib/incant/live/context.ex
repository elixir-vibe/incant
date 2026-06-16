defmodule Incant.Live.Context do
  @moduledoc false

  defstruct [
    :admin,
    :session,
    :base_path,
    :resources,
    :dashboards,
    :datasets,
    :theme,
    :actor,
    :authorization,
    :resource,
    :dashboard,
    :dataset,
    :section,
    :detail_id,
    :form_mode,
    :form_record,
    :form_changeset,
    table_state: %{},
    rows: [],
    selected_row: nil,
    dataset_result: nil,
    pagination: %{},
    dashboard_variables: %{},
    raw_dashboard_variables: %{},
    widget_values: %{}
  ]
end
