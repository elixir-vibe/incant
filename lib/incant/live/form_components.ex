defmodule Incant.Live.FormComponents do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:record, :any, required: true)
  attr(:mode, :atom, required: true)
  attr(:base_path, :string, required: true)

  def resource_form(assigns) do
    ~H"""
    <.card class="p-5">
      <div class="flex items-start justify-between gap-4">
        <div>
          <p class="text-sm text-[var(--incant-text-muted)]">{form_eyebrow(@mode)}</p>
          <h3 class="mt-1 text-xl font-semibold tracking-tight">{form_title(@resource, @record, @mode)}</h3>
        </div>
        <.back_link patch={back_path(@base_path, @resource, @record, @mode)}>
          Cancel
        </.back_link>
      </div>

      <.form :let={_form} for={%{}} as={:resource} phx-change="validate_form" phx-submit="save_form" class="mt-5 grid gap-4 md:grid-cols-2">
        <.form_field :for={field <- Incant.Forms.fields(@resource)} field={field} value={Incant.Live.Rows.field(@record, field.name)} />
        <div class="md:col-span-2">
          <button type="submit" class="rounded-xl bg-[var(--incant-primary)] px-4 py-2 text-sm font-medium text-[var(--incant-text-inverted)]">
            Save
          </button>
        </div>
      </.form>
    </.card>
    """
  end

  attr(:field, Incant.Form.Field, required: true)
  attr(:value, :any, default: nil)

  def form_field(%{field: %{type: :select}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-sm">
      <span class="text-[var(--incant-text-muted)]">{field_label(@field)}</span>
      <.select name={"resource[#{@field.name}]"} value={@value} options={@field.opts[:options] || []} />
    </label>
    """
  end

  def form_field(%{field: %{type: :boolean}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-sm">
      <span class="text-[var(--incant-text-muted)]">{field_label(@field)}</span>
      <.select name={"resource[#{@field.name}]"} value={@value} options={[{"Yes", "true"}, {"No", "false"}]} />
    </label>
    """
  end

  def form_field(assigns) do
    ~H"""
    <label class="grid gap-1 text-sm">
      <span class="text-[var(--incant-text-muted)]">{field_label(@field)}</span>
      <.input type={input_type(@field)} name={"resource[#{@field.name}]"} value={@value} />
    </label>
    """
  end

  defp form_eyebrow(:new), do: "New record"
  defp form_eyebrow(:edit), do: "Edit record"

  defp form_title(resource, record, :edit), do: Incant.Live.Rows.title(record, resource)
  defp form_title(resource, _record, :new), do: "New #{short_module(resource.module)}"

  defp back_path(base_path, resource, record, :edit) do
    case Incant.Live.Rows.id(record) do
      nil -> resource_path(base_path, resource)
      id -> resource_detail_path(base_path, resource, id)
    end
  end

  defp back_path(base_path, resource, _record, :new), do: resource_path(base_path, resource)

  defp field_label(field), do: field.opts[:label] || humanize(field.name)

  defp input_type(%{type: type}) when type in [:number, :date], do: to_string(type)
  defp input_type(%{type: :datetime}), do: "datetime-local"
  defp input_type(_field), do: "text"

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end

  defp short_module(module) do
    module
    |> Module.split()
    |> List.last()
  end
end
