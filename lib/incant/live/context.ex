defmodule Incant.Live.Context do
  @moduledoc false

  defstruct [
    :admin,
    :contract,
    :session,
    :base_path,
    :resources,
    :dashboards,
    :datasets,
    :services,
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
