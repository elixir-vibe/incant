defmodule Incant.UI.Regions.Inspector do
  @moduledoc """
  Record detail/inspector model.
  """

  defstruct [:id, :title, fields: [], groups: [], actions: [], source: nil]

  def from_context(%{form_mode: mode}) when not is_nil(mode), do: nil
  def from_context(%{selected_row: nil}), do: nil

  def from_context(context) do
    %__MODULE__{
      id: "resource.detail",
      title: Incant.Live.Rows.title(context.selected_row, context.resource),
      fields: fields(context.selected_row, context.resource),
      actions: context.resource.table.actions,
      source: context.selected_row
    }
  end

  defp fields(row, resource) do
    Enum.map(resource.table.columns, fn column ->
      value = Incant.Live.Rows.field(row, column.name)

      %{
        id: to_string(column.name),
        label: column.opts[:label] || humanize(column.name),
        value: value,
        display: Incant.Live.Format.value(value, column.opts[:format]),
        format: column.opts[:as] || column.opts[:format]
      }
    end)
  end

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
