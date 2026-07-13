defmodule Incant.UI.Adapters.LiveView.Controls do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Phoenix.LiveView.JS
  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Controls.{DateRange, MultiSelect, Select, Text}
  alias Incant.UI.Regions.FilterBar

  attr(:filter_bar, FilterBar, required: true)
  attr(:env, :map, required: true)

  def filter_bar(assigns) do
    ~H"""
    <div class={Theme.slot(:panel, :root, kind: :filter)}>
      <div class={Theme.slot(:panel, :body, kind: :filter)}>
        <h3 class={Theme.slot(:panel, :title, kind: :filter)}>Filters</h3>
        <.form :let={_form} for={%{}} as={form_as(@filter_bar)} phx-change="incant:event" phx-value-op={filter_bar_op(@filter_bar)} class={Theme.slot(:field, :group)}>
          <.control :if={@filter_bar.search} control={@filter_bar.search} />
          <.control :for={control <- @filter_bar.filters} control={control} />
          <label :if={@filter_bar.id == "resource.filters"} class={Theme.slot(:field, :root)}>
            Rows
            <select name="table[page_size]" class={Theme.slot(:field, :input)}>
              <option :for={size <- [10, 25, 50, 100]} value={size} selected={to_string(size) == to_string(@env.context.table_state.page_size)}>{size}</option>
            </select>
          </label>
        </.form>
      </div>
    </div>
    """
  end

  attr(:variables, :list, required: true)
  attr(:env, :map, required: true)

  def dashboard_variables(assigns) do
    ~H"""
    <div :if={@variables != []} class={Theme.slot(:dashboard, :variables)}>
      <.form :let={_form} for={%{}} as={:var} phx-change="incant:event" phx-value-op="dashboard_variable_commit" class={Theme.slot(:dashboard, :variable_form)}>
        <.dashboard_date_range :for={control <- @variables} :if={match?(%DateRange{}, control)} control={control} />
        <.control :for={control <- @variables} :if={!match?(%DateRange{}, control)} control={control} />
      </.form>
    </div>
    """
  end

  attr(:control, DateRange, required: true)

  def dashboard_date_range(%{control: %DateRange{} = control} = assigns) do
    assigns = assign(assigns, :custom?, date_range_custom?(control.value))

    ~H"""
    <div class={Theme.slot(:dashboard, :date_range)} data-incant-date-range>
      <span class={Theme.slot(:dashboard, :variable_label)}>{@control.label || @control.name}</span>
      <div class={Theme.slot(:dashboard, :preset_group)}>
        <button :for={preset <- ["1h", "24h", "7d", "30d"]} type="button" class={Theme.slot(:dashboard, :preset, active: @control.value == preset)} phx-click={set_dashboard_preset(@control.name, preset)}>
          {preset}
        </button>
        <button type="button" class={Theme.slot(:dashboard, :preset, active: @custom?)} data-incant-date-range-custom>
          Custom
        </button>
      </div>
      <div class={[Theme.slot(:dashboard, :date_fields), !@custom? && "hidden"]} data-incant-date-range-fields>
        <input type="date" name={control_name(@control, "from")} value={map_value(@control.value, "from")} class={Theme.slot(:field, :input)} />
        <input type="date" name={control_name(@control, "to")} value={map_value(@control.value, "to")} class={Theme.slot(:field, :input)} />
      </div>
    </div>
    """
  end

  attr(:filter_bar, FilterBar, required: true)
  attr(:env, :map, required: true)

  def table_filter_bar(assigns) do
    ~H"""
    <div class={Theme.slot(:table, :filter_bar)}>
      <.form :let={_form} for={%{}} as={form_as(@filter_bar)} phx-change="incant:event" phx-value-op={filter_bar_op(@filter_bar)} class={Theme.slot(:table, :filter_form)}>
        <.control :if={@filter_bar.search} control={@filter_bar.search} />
        <.control :for={control <- @filter_bar.filters} control={control} />
        <label :if={@filter_bar.id == "resource.filters"} class={Theme.slot(:field, :root)}>
          Rows
          <select name="table[page_size]" class={Theme.slot(:field, :input)}>
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
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <div class={Theme.slot(:field, :inline)}>
        <input type="text" name={control_name(@control, "from")} value={map_value(@control.value, "from")} placeholder="From" class={Theme.slot(:field, :input, style: :code)} />
        <input type="text" name={control_name(@control, "to")} value={map_value(@control.value, "to")} placeholder="To" class={Theme.slot(:field, :input, style: :code)} />
      </div>
    </label>
    """
  end

  def control(%{control: %Select{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <select name={control_name(@control)} class={Theme.slot(:field, :input)}>
        <option :if={@control.clearable} value="">Any</option>
        <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) == to_string(@control.value)}>
          {option.label}
        </option>
      </select>
    </label>
    """
  end

  def control(%{control: %MultiSelect{} = control} = assigns) do
    assigns = assign(assigns, :values, selected_values(control.value))

    ~H"""
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <select name={control_name(@control) <> "[]"} multiple class={Theme.slot(:field, :input, height: :tall)}>
        <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) in @values}>
          {option.label}
        </option>
      </select>
    </label>
    """
  end

  def control(%{control: %Text{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <input type="text" name={control_name(@control)} value={@control.value} placeholder={@control.placeholder || @control.label} class={Theme.slot(:field, :input)} />
    </label>
    """
  end

  def control(assigns) do
    ~H"""
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <input type="text" name={control_name(@control)} value={@control.value} placeholder={@control.placeholder || @control.label} class={Theme.slot(:field, :input)} />
    </label>
    """
  end

  defp date_range_custom?(value), do: is_map(value)

  defp set_dashboard_preset(name, preset) do
    JS.push("incant:event", value: %{op: "dashboard_variable_commit", var: %{name => preset}})
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
