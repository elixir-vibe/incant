defmodule Incant.UI.FilterState do
  @moduledoc """
  Typed filter state normalized from portable URL and service filter values.
  """

  alias Incant.UI.Controls.{Combobox, DateRange, MultiSelect, Select}
  alias __MODULE__.{Condition, Definition}

  defmodule Definition do
    @moduledoc "A filter field available to the current surface."

    @enforce_keys [:name, :label, :type, :control]
    defstruct [:name, :label, :type, :control]
  end

  defmodule Condition do
    @moduledoc "An applied filter condition."

    @enforce_keys [:name, :label, :type, :value, :display, :control]
    defstruct [:name, :label, :type, :value, :display, :control]
  end

  defstruct [:search, definitions: [], conditions: []]

  @doc false
  def new(search, controls) do
    definitions = Enum.map(controls, &definition/1)

    %__MODULE__{
      search: search,
      definitions: definitions,
      conditions:
        definitions
        |> Enum.filter(&active_value?(&1.control.value))
        |> Enum.map(&condition/1)
    }
  end

  @doc false
  def active?(%__MODULE__{conditions: conditions}, name) do
    Enum.any?(conditions, &(&1.name == to_string(name)))
  end

  @doc false
  def active_count(%__MODULE__{conditions: conditions}), do: length(conditions)

  @doc false
  def any_active?(%__MODULE__{} = state) do
    active_count(state) > 0 or active_value?(state.search && state.search.value)
  end

  defp definition(control) do
    %Definition{
      name: to_string(control.name),
      label: control.label || humanize(control.name),
      type: control_type(control),
      control: control
    }
  end

  defp condition(%Definition{} = definition) do
    %Condition{
      name: definition.name,
      label: definition.label,
      type: definition.type,
      value: definition.control.value,
      display: display_value(definition.control),
      control: definition.control
    }
  end

  defp control_type(%DateRange{}), do: :date_range
  defp control_type(%MultiSelect{}), do: :multi_select
  defp control_type(%Select{}), do: :select
  defp control_type(%Combobox{}), do: :combobox
  defp control_type(control), do: (control.source && control.source.type) || :text

  defp active_value?(nil), do: false
  defp active_value?(""), do: false
  defp active_value?([]), do: false

  defp active_value?(%{} = value),
    do: Enum.any?(value, fn {_key, item} -> active_value?(item) end)

  defp active_value?(_value), do: true

  defp display_value(%DateRange{value: value}) when is_map(value) do
    from = map_value(value, "from")
    to = map_value(value, "to")

    cond do
      active_value?(from) and active_value?(to) -> "#{from} – #{to}"
      active_value?(from) -> "From #{from}"
      active_value?(to) -> "Through #{to}"
      true -> "Any time"
    end
  end

  defp display_value(%MultiSelect{value: values, options: options}) when is_list(values) do
    Enum.map_join(values, ", ", &option_label(options, &1))
  end

  defp display_value(%Select{value: value, options: options}), do: option_label(options, value)

  defp display_value(%Combobox{value: value, options: options}),
    do: option_label(options, value)

  defp display_value(%{value: value}) when value in [true, "true", 1, "1"], do: "Enabled"
  defp display_value(%{value: value}) when value in [false, "false", 0, "0"], do: "Disabled"
  defp display_value(%{value: value}), do: to_string(value)

  defp option_label(options, value) do
    case Enum.find(options || [], &(to_string(&1.value) == to_string(value))) do
      nil -> humanize(value)
      option -> option.label
    end
  end

  defp map_value(map, "from"), do: Map.get(map, "from", Map.get(map, :from, ""))
  defp map_value(map, "to"), do: Map.get(map, "to", Map.get(map, :to, ""))

  defp humanize(value), do: Incant.Naming.label(value)
end
