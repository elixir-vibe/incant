defmodule Incant.UI.Controls do
  @moduledoc """
  Builders for semantic Incant UI controls.
  """

  def from_table_filter(%{type: :date_range} = filter, value, _context) do
    %Incant.UI.Controls.DateRange{
      id: "filters.#{filter.name}",
      name: to_string(filter.name),
      label: filter.opts[:label] || humanize(filter.name),
      role: :filter,
      value: value,
      placeholder: filter.opts[:placeholder],
      clearable: true,
      commit: :change,
      source: filter
    }
  end

  def from_table_filter(%{type: :select} = filter, value, context) do
    %Incant.UI.Controls.Select{
      id: "filters.#{filter.name}",
      name: to_string(filter.name),
      label: filter.opts[:label] || humanize(filter.name),
      role: :filter,
      value: value,
      options: options(filter.opts[:options] || [], filter, context),
      clearable: true,
      source: filter
    }
  end

  def from_table_filter(%{type: :multi_select} = filter, value, context) do
    %Incant.UI.Controls.MultiSelect{
      id: "filters.#{filter.name}",
      name: to_string(filter.name),
      label: filter.opts[:label] || humanize(filter.name),
      role: :filter,
      value: value,
      options: options(filter.opts[:options] || [], filter, context),
      clearable: true,
      source: filter
    }
  end

  def from_table_filter(%{type: :boolean} = filter, value, _context) do
    %Incant.UI.Controls.Boolean{
      id: "filters.#{filter.name}",
      name: to_string(filter.name),
      label: filter.opts[:label] || humanize(filter.name),
      role: :filter,
      value: value,
      options: [%{label: "Enabled", value: "true"}, %{label: "Disabled", value: "false"}],
      clearable: true,
      source: filter
    }
  end

  def from_table_filter(filter, value, _context) do
    %Incant.UI.Controls.Text{
      id: "filters.#{filter.name}",
      name: to_string(filter.name),
      label: filter.opts[:label] || humanize(filter.name),
      role: :filter,
      value: value,
      placeholder: filter.opts[:placeholder],
      source: filter
    }
  end

  def from_dashboard_variable(%{type: :date_range} = variable, context) do
    value =
      Map.get(context.dashboard_variables, to_string(variable.name), variable.opts[:default])

    %Incant.UI.Controls.DateRange{
      id: "variables.#{variable.name}",
      name: to_string(variable.name),
      label: variable.opts[:label] || humanize(variable.name),
      role: :dashboard_variable,
      value: value,
      clearable: true,
      commit: :change,
      source: variable
    }
  end

  def from_dashboard_variable(%{type: :select} = variable, context) do
    struct!(Incant.UI.Controls.Select, variable_attrs(variable, context, options: true))
  end

  def from_dashboard_variable(%{type: :multi_select} = variable, context) do
    struct!(Incant.UI.Controls.MultiSelect, variable_attrs(variable, context, options: true))
  end

  def from_dashboard_variable(variable, context) do
    value =
      Map.get(context.dashboard_variables, to_string(variable.name), variable.opts[:default])

    %Incant.UI.Controls.Text{
      id: "variables.#{variable.name}",
      name: to_string(variable.name),
      label: variable.opts[:label] || humanize(variable.name),
      role: :dashboard_variable,
      value: value,
      source: variable
    }
  end

  def from_form_field(field, context) do
    value = Incant.Live.FormValues.value(context.form_changeset, context.form_record, field.name)
    errors = Incant.Live.FormValues.errors(context.form_changeset, field.name)

    base = %{
      id: "fields.#{field.name}",
      name: to_string(field.name),
      label: field.opts[:label] || humanize(field.name),
      role: :form_field,
      value: value,
      required: field.opts[:required] || false,
      readonly: field.opts[:readonly] || false,
      errors: errors,
      source: field
    }

    field
    |> control_module()
    |> struct!(control_attrs(field, base))
  end

  defp control_attrs(%{type: :select, opts: opts} = field, base),
    do: Map.put(base, :options, options(opts[:options] || [], field, %{form: base}))

  defp control_attrs(_field, base), do: base

  defp control_module(%{type: :select}), do: Incant.UI.Controls.Select
  defp control_module(%{type: :boolean}), do: Incant.UI.Controls.Boolean
  defp control_module(%{type: :number}), do: Incant.UI.Controls.Number
  defp control_module(%{type: :hidden}), do: Incant.UI.Controls.Hidden
  defp control_module(%{type: :date}), do: Incant.UI.Controls.Date
  defp control_module(_field), do: Incant.UI.Controls.Text

  defp options(options, source, context) do
    options
    |> resolve_options(source, context)
    |> Enum.map(fn
      {label, value} -> %{label: to_string(label), value: value}
      value -> %{label: humanize(value), value: value}
    end)
  end

  defp resolve_options(nil, _source, _context), do: []
  defp resolve_options(options, _source, _context) when is_list(options), do: options

  defp resolve_options(options, source, context)
       when is_function(options) or is_tuple(options) do
    Incant.Callback.call(options, %{source: source}, context) || []
  end

  defp variable_attrs(variable, context, opts) do
    attrs = %{
      id: "variables.#{variable.name}",
      name: to_string(variable.name),
      label: variable.opts[:label] || humanize(variable.name),
      role: :dashboard_variable,
      value:
        Map.get(context.dashboard_variables, to_string(variable.name), variable.opts[:default]),
      source: variable
    }

    if opts[:options],
      do: Map.put(attrs, :options, options(variable.opts[:options] || [], variable, context)),
      else: attrs
  end

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
