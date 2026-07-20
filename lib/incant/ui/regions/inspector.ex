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
      source: Incant.Sensitive.redact_row(context.selected_row, context.resource)
    }
  end

  defp fields(row, resource) do
    Enum.map(resource.table.columns, fn column ->
      value = Incant.Live.Rows.field(row, column.name)
      display_value = Incant.Sensitive.redact(value, column.opts)

      %{
        id: to_string(column.name),
        label: column.opts[:label] || humanize(column.name),
        value: display_value,
        display: Incant.Live.Format.value(display_value, column.opts[:format]),
        full: detail_full_value(display_value),
        format: column.opts[:as] || column.opts[:format],
        wide: detail_wide?(column),
        sensitive: Incant.Sensitive.sensitive?(column.opts)
      }
    end)
  end

  defp detail_full_value(nil), do: nil
  defp detail_full_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp detail_full_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp detail_full_value(%Decimal{} = value), do: Decimal.to_string(value, :normal)
  defp detail_full_value(value) when is_binary(value), do: value
  defp detail_full_value(value), do: to_string(value)

  defp detail_wide?(column) do
    column.opts[:format] == :text or column.opts[:wide] == true or
      column.name in [:user_message, :message, :body, :description, :content]
  end

  defp humanize(value), do: Incant.Naming.label(value)
end
