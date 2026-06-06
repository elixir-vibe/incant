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

  def parse(%{"op" => op} = params) do
    explicit_meta = Map.get(params, "meta", %{})
    implicit_meta = Map.drop(params, ["op", "surface", "target", "value", "meta"])

    %__MODULE__{
      op: parse_op(op),
      surface: params["surface"],
      target: params["target"],
      value: params["value"],
      meta: Map.merge(implicit_meta, explicit_meta)
    }
  end

  def parse(params) when is_map(params), do: struct(__MODULE__, params)

  defp parse_op(op) when is_atom(op), do: op
  defp parse_op("navigate"), do: :navigate
  defp parse_op("filter_commit"), do: :filter_commit
  defp parse_op("filter-clear"), do: :filter_clear
  defp parse_op("filter_clear"), do: :filter_clear
  defp parse_op("search_commit"), do: :search_commit
  defp parse_op("sort"), do: :sort
  defp parse_op("paginate"), do: :paginate
  defp parse_op("row_select"), do: :row_select
  defp parse_op("row_action"), do: :row_action
  defp parse_op("bulk_action"), do: :bulk_action
  defp parse_op("form_validate"), do: :form_validate
  defp parse_op("form_submit"), do: :form_submit
  defp parse_op("form_cancel"), do: :form_cancel
  defp parse_op("dashboard_variable_commit"), do: :dashboard_variable_commit
  defp parse_op("widget_refresh"), do: :widget_refresh
  defp parse_op(_op), do: nil
end
