defmodule Incant.UI.Event do
  @moduledoc """
  Normalized event envelope shared by Incant UI adapters.
  """

  @type op ::
          :navigate
          | :filter_commit
          | :filter_clear
          | :search_commit
          | :sort
          | :paginate
          | :row_select
          | :row_action
          | :bulk_action
          | :form_validate
          | :form_submit
          | :form_cancel
          | :dashboard_variable_commit
          | :widget_refresh

  @type t :: %__MODULE__{
          op: op,
          surface: String.t() | nil,
          target: String.t() | nil,
          value: term,
          meta: map
        }

  defstruct [:op, :surface, :target, :value, meta: %{}]

  def serialize(%__MODULE__{} = event) do
    %{
      "op" => event.op && to_string(event.op),
      "surface" => event.surface,
      "target" => event.target,
      "value" => event.value,
      "meta" => event.meta
    }
  end
end
