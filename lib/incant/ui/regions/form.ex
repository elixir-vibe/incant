defmodule Incant.UI.Regions.Form do
  @moduledoc """
  Resource form model.
  """

  defstruct [
    :id,
    :mode,
    fields: [],
    actions: [],
    errors: [],
    dirty: false,
    submit_event: nil,
    validate_event: nil,
    source: nil
  ]

  def from_context(%{form_mode: nil}), do: nil

  def from_context(context) do
    %__MODULE__{
      id: "resource.form",
      mode: context.form_mode,
      fields:
        Enum.map(
          Incant.Forms.fields(context.resource),
          &Incant.UI.Controls.from_form_field(&1, context)
        ),
      source: context.form_changeset
    }
  end
end
