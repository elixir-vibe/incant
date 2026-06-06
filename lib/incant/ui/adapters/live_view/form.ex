defmodule Incant.UI.Adapters.LiveView.Form do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

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
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <div class="flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-3 py-2.5">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{form_eyebrow(@form.mode)}</p>
          <h3 class="mt-1 text-base font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{form_title(@env.context.resource, @env.context.form_record, @form.mode)}</h3>
        </div>
        <.link patch={form_back_path(@env)} class="text-xs font-medium text-[var(--incant-text-highlighted)] hover:underline">Cancel</.link>
      </div>
      <.form for={@phoenix_form} phx-change="incant:event" phx-submit="incant:event" class="grid gap-3 p-3 md:grid-cols-2">
        <input type="hidden" name="op" value="form_validate" />
        <.form_control :for={field <- @form.fields} field={field} />
        <div class="md:col-span-2">
          <button type="submit" name="op" value="form_submit" class="h-8 rounded-md bg-[var(--incant-primary)] px-3 text-sm font-medium text-[var(--incant-text-inverted)] transition hover:brightness-95">Save</button>
        </div>
      </.form>
    </div>
    """
  end

  attr(:field, :map, required: true)

  def form_control(%{field: %Select{} = field} = assigns) do
    assigns = assign(assigns, :field, field)

    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {@field.label}
      <select name={"resource[#{@field.name}]"} class={input_class()} disabled={@field.readonly}>
        <option :for={option <- @field.options || []} value={option.value} selected={to_string(option.value) == to_string(@field.value)}>{option.label}</option>
      </select>
      <.field_errors errors={@field.errors} />
    </label>
    """
  end

  def form_control(assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {@field.label}
      <input type={form_input_type(@field)} name={"resource[#{@field.name}]"} value={form_input_value(@field)} readonly={@field.readonly} class={[input_class(), "font-normal normal-case tracking-normal"]} />
      <.field_errors errors={@field.errors} />
    </label>
    """
  end

  attr(:errors, :list, default: [])

  def field_errors(assigns) do
    ~H"""
    <p :for={error <- @errors} class="text-xs font-normal normal-case tracking-normal text-[var(--incant-error)]">{error}</p>
    """
  end
end
