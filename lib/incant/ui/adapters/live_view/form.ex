defmodule Incant.UI.Adapters.LiveView.Form do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Controls.Select
  alias Incant.UI.Regions.Form

  attr(:form, Form, required: true)
  attr(:env, :map, required: true)

  def resource_form(assigns) do
    assigns =
      assign(
        assigns,
        :phoenix_form,
        Phoenix.Component.to_form(form_source(assigns.form.source), as: :resource)
      )

    ~H"""
    <div class={Theme.slot(:panel, :root, kind: :form)}>
      <.form for={@phoenix_form} id={@form.id} data-incant-resource-form phx-change="incant:event" phx-submit="incant:event" phx-value-op="form_validate" class={Theme.slot(:panel, :body, kind: :form)}>
        <.form_control :for={field <- @form.fields} field={field} />
        <div class={Theme.slot(:panel, :form_actions)}>
          <button type="submit" phx-value-op="form_submit" class={Theme.slot(:button, :base, variant: :primary)}>Save</button>
          <.link patch={form_back_path(@env)} class={Theme.slot(:button, :base, variant: :ghost)}>Cancel</.link>
        </div>
      </.form>
    </div>
    """
  end

  attr(:field, :map, required: true)

  def form_control(%{field: %Select{} = field} = assigns) do
    assigns = assign(assigns, :field, field)

    ~H"""
    <label class={Theme.slot(:field, :root, span: field_span(@field))}>
      {@field.label}
      <select name={"resource[#{@field.name}]"} class={Theme.slot(:field, :input)} disabled={@field.readonly}>
        <option :for={option <- @field.options || []} value={option.value} selected={to_string(option.value) == to_string(@field.value)}>{option.label}</option>
      </select>
      <.field_errors errors={@field.errors} />
    </label>
    """
  end

  def form_control(assigns) do
    ~H"""
    <label class={Theme.slot(:field, :root, span: field_span(@field))}>
      {@field.label}
      <input type={form_input_type(@field)} name={"resource[#{@field.name}]"} value={form_input_value(@field)} readonly={@field.readonly} class={Theme.slot(:field, :input)} />
      <.field_errors errors={@field.errors} />
    </label>
    """
  end

  attr(:errors, :list, default: [])

  def field_errors(assigns) do
    ~H"""
    <p :for={error <- @errors} class={Theme.slot(:field, :error)}>{error}</p>
    """
  end

  defp field_span(%{source: %{type: type}}) when type in [:text, :textarea], do: :full
  defp field_span(_field), do: :auto
end
