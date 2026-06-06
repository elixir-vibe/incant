defmodule Incant.Live.Resource.Form do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components
  import Incant.Live.Routes

  attr(:resource, Incant.Resource.Metadata, required: true)
  attr(:record, :any, required: true)
  attr(:changeset, :any, default: nil)
  attr(:mode, :atom, required: true)
  attr(:base_path, :string, required: true)

  def view(assigns) do
    assigns =
      assign(
        assigns,
        :form,
        Phoenix.Component.to_form(form_source(assigns.changeset), as: :resource)
      )

    ~H"""
    <.card class="overflow-hidden">
      <div class="flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-3 py-2.5">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{form_eyebrow(@mode)}</p>
          <h3 class="mt-1 text-base font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{form_title(@resource, @record, @mode)}</h3>
        </div>
        <.back_link patch={back_path(@base_path, @resource, @record, @mode)} class="text-xs">
          Cancel
        </.back_link>
      </div>

      <pre :if={@changeset && !form_like?(@changeset)} class="m-3 overflow-auto rounded-md bg-[var(--incant-bg-muted)] p-2 text-xs text-[var(--incant-text-muted)]"><%= inspect(@changeset, pretty: true) %></pre>

      <.form for={@form} phx-change="validate_form" phx-submit="save_form" class="grid gap-3 p-3 md:grid-cols-2">
        <.form_field :for={field <- Incant.Forms.fields(@resource)} field={field} value={form_value(@changeset, @record, field.name)} errors={field_errors(@changeset, field.name)} />
        <div class="md:col-span-2">
          <button type="submit" class="h-8 rounded-md bg-[var(--incant-primary)] px-3 text-sm font-medium text-[var(--incant-text-inverted)] transition hover:brightness-95">
            Save
          </button>
        </div>
      </.form>
    </.card>
    """
  end

  attr(:field, Incant.Form.Field, required: true)
  attr(:value, :any, default: nil)
  attr(:errors, :list, default: [])

  def form_field(%{field: %{type: :select}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {field_label(@field)}
      <.select name={"resource[#{@field.name}]"} value={@value} options={@field.opts[:options] || []} disabled={@field.opts[:readonly]} />
      <.field_errors errors={@errors} />
    </label>
    """
  end

  def form_field(%{field: %{type: :hidden}} = assigns) do
    ~H"""
    <input type="hidden" name={"resource[#{@field.name}]"} value={@value} />
    """
  end

  def form_field(%{field: %{type: :textarea}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)] md:col-span-2">
      {field_label(@field)}
      <textarea
        name={"resource[#{@field.name}]"}
        readonly={@field.opts[:readonly]}
        rows={@field.opts[:rows] || 5}
        class="rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 py-2 text-sm font-normal normal-case tracking-normal text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]"
      >{to_string(@value || "")}</textarea>
      <.field_errors errors={@errors} />
    </label>
    """
  end

  def form_field(%{field: %{type: :boolean}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {field_label(@field)}
      <.select name={"resource[#{@field.name}]"} value={@value} options={[{"Yes", "true"}, {"No", "false"}]} disabled={@field.opts[:readonly]} />
      <.field_errors errors={@errors} />
    </label>
    """
  end

  def form_field(assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {field_label(@field)}
      <.input type={input_type(@field)} name={"resource[#{@field.name}]"} value={input_value(@field, @value)} readonly={@field.opts[:readonly]} step={input_step(@field)} class="font-normal normal-case tracking-normal" />
      <.field_errors errors={@errors} />
    </label>
    """
  end

  attr(:errors, :list, default: [])

  def field_errors(assigns) do
    ~H"""
    <p :for={error <- @errors} class="text-xs font-normal normal-case tracking-normal text-[var(--incant-error)]">{error}</p>
    """
  end

  defp form_value(%{changes: changes}, record, field) when is_map(changes) do
    Map.get(changes, field, Incant.Live.Rows.field(record, field))
  end

  defp form_value(_changeset, record, field), do: Incant.Live.Rows.field(record, field)

  defp field_errors(%{action: nil}, _field), do: []

  defp field_errors(%{errors: errors}, field) when is_list(errors) do
    errors
    |> Keyword.get_values(field)
    |> Enum.map(fn
      {message, opts} -> interpolate_error(message, opts)
      message -> to_string(message)
    end)
  end

  defp field_errors(_changeset, _field), do: []

  defp interpolate_error(message, opts) do
    Enum.reduce(opts, message, fn {key, value}, message ->
      String.replace(message, "%{#{key}}", to_string(value))
    end)
  end

  defp form_source(nil), do: %{}
  defp form_source(%{__struct__: Ecto.Changeset, params: params}) when is_map(params), do: params

  defp form_source(%{__struct__: Ecto.Changeset, changes: changes}) when is_map(changes),
    do: changes

  defp form_source(changeset), do: changeset

  defp form_like?(%{__struct__: Phoenix.HTML.Form}), do: true
  defp form_like?(%{__struct__: Ecto.Changeset}), do: true
  defp form_like?(_value), do: false

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

  defp input_type(%{type: type}) when type in [:number, :date, :time], do: to_string(type)
  defp input_type(%{type: :datetime}), do: "datetime-local"
  defp input_type(_field), do: "text"

  defp input_step(%{opts: opts, type: type}) do
    Keyword.get_lazy(opts, :step, fn -> default_step(type) end)
  end

  defp default_step(:number), do: "any"
  defp default_step(:time), do: "1"
  defp default_step(:datetime), do: "1"
  defp default_step(_type), do: nil

  defp input_value(%{type: :datetime}, %DateTime{} = value) do
    value
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_iso8601()
  end

  defp input_value(%{type: :datetime}, %NaiveDateTime{} = value) do
    value
    |> NaiveDateTime.truncate(:second)
    |> NaiveDateTime.to_iso8601()
  end

  defp input_value(%{type: :time}, %Time{} = value),
    do: value |> Time.truncate(:second) |> Time.to_iso8601()

  defp input_value(_field, nil), do: nil
  defp input_value(_field, %Decimal{} = value), do: Decimal.to_string(value)
  defp input_value(_field, value), do: value

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
