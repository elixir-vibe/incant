defmodule Incant.UI.Adapters.LiveView.Controls do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Controls.{DateRange, MultiSelect, Select, Text}
  alias Incant.UI.Regions.FilterBar

  attr(:filter_bar, FilterBar, required: true)
  attr(:env, :map, required: true)

  def filter_bar(assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <.form :let={_form} for={%{}} as={form_as(@filter_bar)} phx-change="incant:event" phx-value-op={filter_bar_op(@filter_bar)} class="grid gap-2 p-2 md:grid-cols-[minmax(12rem,1fr)_minmax(10rem,1fr)_minmax(14rem,1fr)_8rem]">
        <.control :if={@filter_bar.search} control={@filter_bar.search} />
        <.control :for={control <- @filter_bar.filters} control={control} />
        <label :if={@filter_bar.id == "resource.filters"} class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
          Rows
          <select name="table[page_size]" class={input_class()}>
            <option :for={size <- [10, 25, 50, 100]} value={size} selected={to_string(size) == to_string(@env.context.table_state.page_size)}>{size}</option>
          </select>
        </label>
      </.form>
    </div>
    """
  end

  attr(:control, :any, required: true)

  def control(%{control: %DateRange{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <div class="grid grid-cols-2 gap-2">
      <input type="text" name={control_name(@control, "from")} value={map_value(@control.value, "from")} placeholder="From" class={[input_class(), "font-mono"]} />
      <input type="text" name={control_name(@control, "to")} value={map_value(@control.value, "to")} placeholder="To" class={[input_class(), "font-mono"]} />
    </div>
    """
  end

  def control(%{control: %Select{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <select name={control_name(@control)} class={input_class()}>
      <option :if={@control.clearable} value="">{@control.name}</option>
      <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) == to_string(@control.value)}>
        {option.label}
      </option>
    </select>
    """
  end

  def control(%{control: %MultiSelect{} = control} = assigns) do
    assigns = assign(assigns, :values, selected_values(control.value))

    ~H"""
    <select name={control_name(@control) <> "[]"} multiple class={[input_class(), "min-h-20"]}>
      <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) in @values}>
        {option.label}
      </option>
    </select>
    """
  end

  def control(%{control: %Text{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <input type="text" name={control_name(@control)} value={@control.value} placeholder={@control.placeholder || @control.label} class={input_class()} />
    """
  end

  def control(assigns) do
    ~H"""
    <input type="text" name={control_name(@control)} value={@control.value} placeholder={@control.placeholder || @control.label} class={input_class()} />
    """
  end

  defp form_as(%{id: "dashboard.variables"}), do: :var
  defp form_as(_filter_bar), do: :table

  defp filter_bar_op(%{id: "dashboard.variables"}), do: "dashboard_variable_commit"
  defp filter_bar_op(_filter_bar), do: "filter_commit"

  defp control_name(%{role: :search}), do: "table[search]"
  defp control_name(%{role: :filter, name: name}), do: "table[filters][#{name}]"
  defp control_name(%{role: :dashboard_variable, name: name}), do: "var[#{name}]"
  defp control_name(%{name: name}), do: name

  defp control_name(%{role: :filter, name: name}, part), do: "table[filters][#{name}][#{part}]"
  defp control_name(%{role: :dashboard_variable, name: name}, part), do: "var[#{name}][#{part}]"
end
