defmodule Incant.UI.Surfaces.ResourceIndex do
  @moduledoc """
  Resource index/list surface model.
  """

  alias Incant.UI.Regions.{FilterBar, Form, Inspector, Table}

  defstruct [
    :id,
    :title,
    :resource,
    :filter_bar,
    :table,
    :detail,
    :form,
    :actions,
    regions: [],
    context: nil
  ]

  def from_context(context, title) do
    filter_bar = FilterBar.from_context(context)
    table = Table.from_context(context)
    detail = Inspector.from_context(context)
    form = Form.from_context(context)

    %__MODULE__{
      id: "resource.#{context.resource.module}",
      title: title,
      resource: context.resource,
      filter_bar: filter_bar,
      table: table,
      detail: detail,
      form: form,
      actions: [],
      regions: Enum.reject([filter_bar, form, detail, table], &is_nil/1),
      context: context
    }
  end
end
