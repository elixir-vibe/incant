defmodule Incant.UI.Adapters.LiveView.Controls do
  @moduledoc false

  use Phoenix.Component

  import Incant.UI.Adapters.LiveView.Helpers

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Controls.{Boolean, Combobox, DateRange, MultiSelect, Select, Text}
  alias Incant.UI.FilterState
  alias Incant.UI.FilterState.Definition
  alias Incant.UI.Regions.FilterBar
  alias Phoenix.LiveView.JS

  attr(:filter_bar, FilterBar, required: true)
  attr(:env, :map, required: true)

  def filter_bar(assigns), do: table_filter_bar(assigns)

  attr(:filter_bar, FilterBar, required: true)
  attr(:env, :map, required: true)

  def table_filter_bar(assigns) do
    state =
      assigns.filter_bar.state ||
        FilterState.new(assigns.filter_bar.search, assigns.filter_bar.filters)

    assigns =
      assigns
      |> Map.put(:state, state)
      |> Map.put(:dialog_id, filter_dialog_id(assigns.filter_bar.id))

    ~H"""
    <div class={Theme.slot(:filters, :root)}>
      <div class={Theme.slot(:filters, :toolbar)}>
        <.filter_search :if={@state.search} control={@state.search} />

        <div class={Theme.slot(:filters, :chips)} aria-label="Active filters">
          <span :for={condition <- @state.conditions} class={Theme.slot(:filters, :chip)}>
            <button
              type="button"
              class={Theme.slot(:filters, :chip_edit)}
              data-incant-filter-open={@dialog_id}
              data-incant-filter-focus={filter_editor_id(condition.name)}
              aria-label={"Edit #{condition.label} filter"}
            >
              <span class={Theme.slot(:filters, :chip_label)}>{condition.label}</span>
              <span>{condition.display}</span>
            </button>
            <button
              type="button"
              class={Theme.slot(:filters, :chip_remove)}
              phx-click="incant:event"
              phx-value-op="filter_clear"
              phx-value-target={condition.name}
              aria-label={"Remove #{condition.label} filter"}
            >
              <span aria-hidden="true">×</span>
            </button>
          </span>
        </div>

        <button
          type="button"
          class={Theme.slot(:filters, :trigger)}
          data-incant-filter-open={@dialog_id}
          aria-haspopup="dialog"
        >
          <span class="hidden sm:inline">Add filter</span>
          <span class="sm:hidden">Filters</span>
          <span :if={FilterState.active_count(@state) > 0} class={Theme.slot(:filters, :count)}>
            {FilterState.active_count(@state)}
          </span>
        </button>

        <button
          :if={FilterState.any_active?(@state)}
          type="button"
          class={Theme.slot(:filters, :clear_all)}
          phx-click="incant:event"
          phx-value-op="filter_clear"
          phx-value-target="all"
        >
          Clear all
        </button>
      </div>

      <dialog id={@dialog_id} class={Theme.slot(:filters, :dialog)} aria-labelledby={@dialog_id <> "-title"} data-incant-filter-dialog>
        <div class={Theme.slot(:filters, :dialog_header)}>
          <div>
            <h3 id={@dialog_id <> "-title"} class={Theme.slot(:filters, :dialog_title)}>Filters</h3>
            <p class={Theme.slot(:filters, :dialog_description)}>Choose a field, then apply its value.</p>
          </div>
          <button type="button" class={Theme.slot(:filters, :dialog_close)} data-incant-filter-close aria-label="Close filters">×</button>
        </div>

        <div class={Theme.slot(:filters, :dialog_body)}>
          <p :if={@state.definitions == []} class={Theme.slot(:filters, :empty)}>No filters are available.</p>
          <.filter_definition
            :for={definition <- @state.definitions}
            definition={definition}
            active={FilterState.active?(@state, definition.name)}
          />
        </div>

        <div class={Theme.slot(:filters, :dialog_footer)}>
          <button
            :if={FilterState.any_active?(@state)}
            type="button"
            class={Theme.slot(:button, :base, variant: :ghost, size: :sm)}
            phx-click="incant:event"
            phx-value-op="filter_clear"
            phx-value-target="all"
            data-incant-filter-close
          >
            Clear all
          </button>
          <button type="button" class={Theme.slot(:button, :base, variant: :outline, size: :sm)} data-incant-filter-close>Done</button>
        </div>
      </dialog>
    </div>
    """
  end

  attr(:control, Text, required: true)

  def filter_search(assigns) do
    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-change="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :search_form)}>
      <label for="incant-table-search" class="sr-only">Search</label>
      <input
        id="incant-table-search"
        type="search"
        name="table[search]"
        value={@control.value}
        placeholder={@control.placeholder || "Search"}
        phx-debounce="300"
        class={Theme.slot(:filters, :search)}
      />
    </.form>
    """
  end

  attr(:definition, Definition, required: true)
  attr(:active, :boolean, default: false)

  def filter_definition(assigns) do
    ~H"""
    <details class={Theme.slot(:filters, :definition)} data-incant-filter-definition={@definition.name}>
      <summary class={Theme.slot(:filters, :definition_summary)}>
        <span>{@definition.label}</span>
        <span class={Theme.slot(:filters, :definition_meta)}>
          <span :if={@active}>Active · </span>{filter_type_label(@definition.type)}
        </span>
      </summary>
      <div class={Theme.slot(:filters, :definition_editor)}>
        <.filter_editor control={@definition.control} />
        <button
          :if={@active}
          type="button"
          class={Theme.slot(:filters, :clear_filter)}
          phx-click="incant:event"
          phx-value-op="filter_clear"
          phx-value-target={@definition.name}
        >
          Clear {@definition.label}
        </button>
      </div>
    </details>
    """
  end

  attr(:control, :any, required: true)

  def filter_editor(%{control: %DateRange{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-submit="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :editor_form)}>
      <div class={Theme.slot(:filters, :date_editor)}>
        <div class={Theme.slot(:filters, :date_presets)} aria-label="Date range presets">
          <button :for={{label, days} <- [{"Today", 1}, {"7 days", 7}, {"30 days", 30}]} type="button" class={Theme.slot(:filters, :date_preset)} data-incant-filter-date-preset={days}>
            {label}
          </button>
        </div>
        <div class={Theme.slot(:filters, :date_fields)}>
          <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name) <> "-from"}>
            From
            <input id={filter_editor_id(@control.name) <> "-from"} type="date" name={control_name(@control, "from")} value={map_value(@control.value, "from")} class={Theme.slot(:field, :input)} />
          </label>
          <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name) <> "-to"}>
            To
            <input id={filter_editor_id(@control.name) <> "-to"} type="date" name={control_name(@control, "to")} value={map_value(@control.value, "to")} class={Theme.slot(:field, :input)} />
          </label>
        </div>
      </div>
      <button type="submit" class={Theme.slot(:button, :base, variant: :primary, size: :sm)} data-incant-filter-apply>Apply filter</button>
    </.form>
    """
  end

  def filter_editor(%{control: %MultiSelect{} = control} = assigns) do
    assigns = assign(assigns, :values, selected_values(control.value))

    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-submit="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :editor_form)}>
      <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name)}>
        Values
        <select id={filter_editor_id(@control.name)} name={control_name(@control) <> "[]"} multiple class={Theme.slot(:field, :input, height: :tall)}>
          <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) in @values}>{option.label}</option>
        </select>
      </label>
      <button type="submit" class={Theme.slot(:button, :base, variant: :primary, size: :sm)} data-incant-filter-apply>Apply filter</button>
    </.form>
    """
  end

  def filter_editor(%{control: %Boolean{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-submit="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :editor_form)}>
      <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name)}>
        State
        <select id={filter_editor_id(@control.name)} name={control_name(@control)} class={Theme.slot(:field, :input)}>
          <option value="">Any state</option>
          <option value="true" selected={to_string(@control.value) == "true"}>Enabled</option>
          <option value="false" selected={to_string(@control.value) == "false"}>Disabled</option>
        </select>
      </label>
      <button type="submit" class={Theme.slot(:button, :base, variant: :primary, size: :sm)} data-incant-filter-apply>Apply filter</button>
    </.form>
    """
  end

  def filter_editor(%{control: %Combobox{} = control} = assigns) do
    assigns =
      assigns
      |> assign(:control, control)
      |> assign(:list_id, filter_editor_id(control.name) <> "-options")

    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-submit="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :editor_form)}>
      <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name)}>
        Value
        <input
          id={filter_editor_id(@control.name)}
          type="text"
          name={control_name(@control)}
          value={@control.value}
          list={@list_id}
          autocomplete="off"
          aria-autocomplete="list"
          placeholder={@control.placeholder || "Type to search"}
          class={Theme.slot(:field, :input)}
        />
        <datalist id={@list_id}>
          <option :for={option <- @control.options || []} value={option.value}>{option.label}</option>
        </datalist>
      </label>
      <button type="submit" class={Theme.slot(:button, :base, variant: :primary, size: :sm)} data-incant-filter-apply>Apply filter</button>
    </.form>
    """
  end

  def filter_editor(%{control: %Select{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-submit="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :editor_form)}>
      <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name)}>
        Value
        <select id={filter_editor_id(@control.name)} name={control_name(@control)} class={Theme.slot(:field, :input)}>
          <option value="">Any value</option>
          <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) == to_string(@control.value)}>{option.label}</option>
        </select>
      </label>
      <button type="submit" class={Theme.slot(:button, :base, variant: :primary, size: :sm)} data-incant-filter-apply>Apply filter</button>
    </.form>
    """
  end

  def filter_editor(assigns) do
    ~H"""
    <.form :let={_form} for={%{}} as={:table} phx-submit="incant:event" phx-value-op="filter_commit" class={Theme.slot(:filters, :editor_form)}>
      <label class={Theme.slot(:filters, :editor_field)} for={filter_editor_id(@control.name)}>
        Value
        <input id={filter_editor_id(@control.name)} type="text" name={control_name(@control)} value={@control.value} placeholder={@control.placeholder || @control.label} class={Theme.slot(:field, :input)} />
      </label>
      <button type="submit" class={Theme.slot(:button, :base, variant: :primary, size: :sm)} data-incant-filter-apply>Apply filter</button>
    </.form>
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
        <button :for={preset <- ["1h", "24h", "7d", "30d"]} type="button" class={Theme.slot(:dashboard, :preset, active: @control.value == preset)} phx-click={set_dashboard_preset(@control.name, preset)}>{preset}</button>
        <button type="button" class={Theme.slot(:dashboard, :preset, active: @custom?)} data-incant-date-range-custom>Custom</button>
      </div>
      <div class={[Theme.slot(:dashboard, :date_fields), !@custom? && "hidden"]} data-incant-date-range-fields>
        <input type="date" name={control_name(@control, "from")} value={map_value(@control.value, "from")} aria-label={"#{@control.label} from"} class={Theme.slot(:field, :input)} />
        <input type="date" name={control_name(@control, "to")} value={map_value(@control.value, "to")} aria-label={"#{@control.label} to"} class={Theme.slot(:field, :input)} />
      </div>
    </div>
    """
  end

  attr(:control, :any, required: true)

  def control(%{control: %DateRange{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <fieldset class={Theme.slot(:field, :root)}>
      <legend>{@control.label || @control.name}</legend>
      <div class={Theme.slot(:field, :inline)}>
        <input type="date" name={control_name(@control, "from")} value={map_value(@control.value, "from")} aria-label={"#{@control.label} from"} class={Theme.slot(:field, :input)} />
        <input type="date" name={control_name(@control, "to")} value={map_value(@control.value, "to")} aria-label={"#{@control.label} to"} class={Theme.slot(:field, :input)} />
      </div>
    </fieldset>
    """
  end

  def control(%{control: %Select{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <select name={control_name(@control)} class={Theme.slot(:field, :input)}>
        <option :if={@control.clearable} value="">Any</option>
        <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) == to_string(@control.value)}>{option.label}</option>
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
        <option :for={option <- @control.options || []} value={option.value} selected={to_string(option.value) in @values}>{option.label}</option>
      </select>
    </label>
    """
  end

  def control(%{control: %Boolean{} = control} = assigns) do
    assigns = assign(assigns, :control, control)

    ~H"""
    <label class={Theme.slot(:field, :root)}>
      {@control.label || @control.name}
      <select name={control_name(@control)} class={Theme.slot(:field, :input)}>
        <option value="">Any</option>
        <option value="true" selected={to_string(@control.value) == "true"}>Enabled</option>
        <option value="false" selected={to_string(@control.value) == "false"}>Disabled</option>
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

  defp filter_dialog_id(id), do: "incant-filter-dialog-" <> String.replace(id, ".", "-")
  defp filter_editor_id(name), do: "incant-filter-" <> String.replace(to_string(name), "_", "-")

  defp filter_type_label(:date_range), do: "Date range"
  defp filter_type_label(:multi_select), do: "Multiple choice"
  defp filter_type_label(:select), do: "Choice"
  defp filter_type_label(:combobox), do: "Autocomplete"
  defp filter_type_label(:boolean), do: "Yes or no"
  defp filter_type_label(_type), do: "Text"

  defp control_name(%{role: :search}), do: "table[search]"
  defp control_name(%{role: :filter, name: name}), do: "table[filters][#{name}]"
  defp control_name(%{role: :dashboard_variable, name: name}), do: "var[#{name}]"
  defp control_name(%{name: name}), do: name

  defp control_name(%{role: :filter, name: name}, part), do: "table[filters][#{name}][#{part}]"
  defp control_name(%{role: :dashboard_variable, name: name}, part), do: "var[#{name}][#{part}]"
end
