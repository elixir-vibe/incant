defmodule Incant.Live.Context do
  @moduledoc false

  defstruct [
    :base_path,
    :resource,
    :dashboard,
    :section,
    :detail_id,
    :form_mode,
    :form_record,
    :form_changeset,
    table_state: %{},
    rows: [],
    selected_row: nil,
    widget_values: %{}
  ]
end
