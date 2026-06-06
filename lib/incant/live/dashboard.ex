defmodule Incant.Live.Dashboard do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Components

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:dashboard, context.dashboard)
      |> assign(:widget_values, context.widget_values)
      |> assign(:variables, context.dashboard_variables)

    ~H"""
    <section class="space-y-3">
      <.card class="flex flex-col gap-3 p-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Dashboard</p>
          <h2 class="text-lg font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{@dashboard.title}</h2>
        </div>

        <.form :let={_form} :if={@dashboard.variables != []} for={%{}} as={:var} phx-change="dashboard_variables" class="grid gap-2 md:grid-cols-4">
          <.variable_control :for={variable <- @dashboard.variables} variable={variable} value={Map.get(@variables, to_string(variable.name), variable.opts[:default])} />
        </.form>
      </.card>

      <div class="grid grid-cols-1 gap-3 xl:grid-cols-12">
        <.widget_card
          :for={widget <- @dashboard.widgets}
          widget={widget}
          value={Map.get(@widget_values, widget.id)}
          loaded={Map.has_key?(@widget_values, widget.id)}
          error={widget_error_message(Map.get(@widget_values, widget.id))}
        />
      </div>
    </section>
    """
  end

  attr(:variable, Incant.Dashboard.Variable, required: true)
  attr(:value, :any, default: nil)

  def variable_control(%{variable: %{type: :select}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {widget_label(@variable)}
      <.select name={"var[#{@variable.name}]"} value={@value} options={@variable.opts[:options] || []} />
    </label>
    """
  end

  def variable_control(%{variable: %{type: :multi_select}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {widget_label(@variable)}
      <.select name={"var[#{@variable.name}][]"} value={@value} options={@variable.opts[:options] || []} multiple class="min-h-20" />
    </label>
    """
  end

  def variable_control(%{variable: %{type: :date_range}} = assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)] md:col-span-2">
      {widget_label(@variable)}
      <div class="grid grid-cols-2 gap-2">
        <.input type="date" name={"var[#{@variable.name}][from]"} value={map_value(@value, "from")} />
        <.input type="date" name={"var[#{@variable.name}][to]"} value={map_value(@value, "to")} />
      </div>
    </label>
    """
  end

  def variable_control(assigns) do
    ~H"""
    <label class="grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">
      {widget_label(@variable)}
      <.input type="text" name={"var[#{@variable.name}]"} value={@value} />
    </label>
    """
  end

  attr(:widget, Incant.Dashboard.Widget, required: true)
  attr(:value, :any, default: nil)
  attr(:loaded, :boolean, default: false)
  attr(:error, :any, default: nil)

  def widget_card(%{widget: %{type: :stat}} = assigns) do
    ~H"""
    <.card class="p-3" style={widget_style(@widget)}>
      <div class="flex items-start justify-between gap-3">
        <div>
          <p class="text-xs font-medium text-[var(--incant-text-muted)]">{widget_label(@widget)}</p>
          <div class="mt-2 text-2xl font-semibold tracking-tight text-[var(--incant-text-highlighted)]">
            <%= if @error do %>
              <span class="text-base text-[var(--incant-error)]">{@error}</span>
            <% else %>
              <%= if @loaded do %>
                {format_widget_value(@value, @widget)}
              <% else %>
                <span class="text-[var(--incant-text-dimmed)]">—</span>
              <% end %>
            <% end %>
          </div>
        </div>
        <.pill class="border-0 bg-[color-mix(in_oklab,var(--incant-primary)_10%,transparent)] text-[var(--incant-primary)]">stat</.pill>
      </div>
    </.card>
    """
  end

  def widget_card(%{widget: %{type: :timeseries}} = assigns) do
    ~H"""
    <.card class="p-3" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Timeseries</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{widget_label(@widget)}</h3>
        </div>
        <.pill>span {@widget.opts[:span] || "auto"}</.pill>
      </div>
      <%= if @error do %>
        <.widget_error message={@error} />
      <% else %>
        <%= if @loaded && is_list(@value) && @value != [] do %>
          <div class="mt-3 flex h-36 items-end gap-1.5 rounded-md bg-[var(--incant-bg-muted)] p-3">
            <div :for={point <- @value} class="min-w-2 flex-1 rounded-sm bg-[var(--incant-primary)]" style={"height: #{bar_height(point, @value)}%;"}></div>
          </div>
        <% else %>
          <div class="mt-3 flex h-36 items-center justify-center rounded-md bg-[var(--incant-bg-muted)] text-sm text-[var(--incant-text-muted)]">
            Chart renderer coming soon
          </div>
        <% end %>
      <% end %>
    </.card>
    """
  end

  def widget_card(%{widget: %{type: :table}} = assigns) do
    ~H"""
    <.card class="overflow-hidden" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] p-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Table</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{widget_label(@widget)}</h3>
        </div>
        <.pill>span {@widget.opts[:span] || "auto"}</.pill>
      </div>
      <%= if @error do %>
        <.widget_error message={@error} />
      <% else %>
        <%= if @loaded && is_list(@value) && @value != [] do %>
          <table class="min-w-full text-sm">
            <thead class="bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]">
              <tr>
                <th :for={column <- table_columns(@value)} class="h-8 px-3 font-medium">{column}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-[var(--incant-border-muted)]">
              <tr :for={row <- @value} class="h-9">
                <td :for={column <- table_columns(@value)} class="px-3 py-1.5 text-[var(--incant-text-toned)]">{Map.get(row, column)}</td>
              </tr>
            </tbody>
          </table>
        <% else %>
          <div class="border-t border-[var(--incant-border)] p-6 text-center text-sm text-[var(--incant-text-muted)]">
            Table widget renderer coming soon
          </div>
        <% end %>
      <% end %>
    </.card>
    """
  end

  def widget_card(assigns) do
    ~H"""
    <.card class="p-3" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{@widget.type}</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{widget_label(@widget)}</h3>
        </div>
        <.pill>span {@widget.opts[:span] || "auto"}</.pill>
      </div>
      <pre class="mt-3 overflow-auto rounded-md bg-[var(--incant-bg-muted)] p-2 text-xs text-[var(--incant-text-muted)]"><%= inspect(@widget.opts, pretty: true) %></pre>
    </.card>
    """
  end

  attr(:message, :string, required: true)

  def widget_error(assigns) do
    ~H"""
    <div class="mt-3 rounded-md bg-[color-mix(in_oklab,var(--incant-error)_10%,transparent)] p-3 text-sm text-[var(--incant-error)]">
      Widget failed: {@message}
    </div>
    """
  end

  defp widget_error_message({:error, message}), do: message
  defp widget_error_message(_value), do: nil

  defp bar_height(point, points) do
    value = numeric_value(point)
    max_value = points |> Enum.map(&numeric_value/1) |> Enum.max(fn -> 1 end)

    if max_value > 0, do: max(round(value / max_value * 100), 4), else: 4
  end

  defp numeric_value(%{value: value}) when is_number(value), do: value
  defp numeric_value(%{"value" => value}) when is_number(value), do: value
  defp numeric_value(%{y: value}) when is_number(value), do: value
  defp numeric_value(%{"y" => value}) when is_number(value), do: value
  defp numeric_value(value) when is_number(value), do: value
  defp numeric_value(_value), do: 0

  defp table_columns([row | _]) when is_map(row), do: Map.keys(row)
  defp table_columns(_rows), do: []

  defp widget_style(widget) do
    case widget.opts[:span] do
      nil -> nil
      span -> "grid-column: span #{span} / span #{span};"
    end
  end

  defp widget_label(%{id: id, opts: opts}), do: opts[:label] || humanize(id)
  defp widget_label(%{name: name, opts: opts}), do: opts[:label] || humanize(name)

  defp map_value(value, key) when is_map(value), do: Map.get(value, key, "") |> input_value()
  defp map_value(_value, _key), do: ""

  defp input_value(%Date{} = date), do: Date.to_iso8601(date)
  defp input_value(value), do: value

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end

  defp format_widget_value(value, widget),
    do: Incant.Live.Format.value(value, widget.opts[:format])
end
