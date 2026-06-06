defmodule Incant.UI.Adapters.LiveView do
  @moduledoc """
  Default Incant UI adapter backed by Phoenix LiveView components.
  """

  @behaviour Incant.UI.Adapter

  use Phoenix.Component

  import Incant.Live.Routes

  alias Incant.Live.Authorization
  alias Incant.UI.Controls.{DateRange, MultiSelect, Select, Text}
  alias Incant.UI.Document
  alias Incant.UI.Regions.{FilterBar, Form, Inspector, Table, WidgetGrid}
  alias Incant.UI.Surfaces.{Dashboard, Empty, ResourceIndex}

  @impl Incant.UI.Adapter
  def render(%Document{} = document, env) do
    assigns = %{document: document, env: env, nav: document.nav, surface: document.surface}

    ~H"""
    <div class="min-h-screen bg-[var(--incant-bg)] text-[var(--incant-text)] antialiased">
      <aside class="fixed inset-y-0 left-0 hidden w-56 border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] lg:block">
        <div class="border-b border-[var(--incant-border-muted)] px-3 py-2.5">
          <div class="text-[11px] font-semibold uppercase tracking-[0.22em] text-[var(--incant-primary)]">Incant</div>
          <div class="mt-1 text-sm font-medium text-[var(--incant-text-highlighted)]">{short_module(@env.admin)}</div>
        </div>
        <.nav nav={@nav} />
      </aside>

      <main class="lg:pl-56">
        <div class="sticky top-0 z-10 border-b border-[var(--incant-border)] bg-[color-mix(in_oklab,var(--incant-bg-elevated)_92%,transparent)] px-4 backdrop-blur lg:px-5">
          <div class="flex h-11 items-center justify-between gap-3">
            <h1 class="min-w-0 truncate text-sm font-semibold text-[var(--incant-text-highlighted)]">{@document.title}</h1>
            <div class="hidden shrink-0 text-xs text-[var(--incant-text-muted)] md:block">
              {length(@nav.items |> Enum.filter(&(&1.kind == :resource)))} resources · {length(@nav.items |> Enum.filter(&(&1.kind == :dashboard)))} dashboards
            </div>
          </div>
        </div>

        <div class="p-3 lg:p-4">
          <.render_surface surface={@surface} env={@env} />
        </div>
      </main>
    </div>
    """
  end

  def render(node, _env) do
    assigns = %{node: node}

    ~H"""
    <pre class="rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-muted)] p-3 text-xs text-[var(--incant-text-muted)]"><%= inspect(@node, pretty: true) %></pre>
    """
  end

  attr(:nav, :map, required: true)

  def nav(assigns) do
    ~H"""
    <nav class="space-y-4 px-2 py-3">
      <.nav_group title="Dashboards" items={Enum.filter(@nav.items, &(&1.group == :dashboards))} active_id={@nav.active_id} />
      <.nav_group title="Resources" items={Enum.filter(@nav.items, &(&1.group == :resources))} active_id={@nav.active_id} />
    </nav>
    """
  end

  attr(:title, :string, required: true)
  attr(:items, :list, required: true)
  attr(:active_id, :string, default: nil)

  def nav_group(assigns) do
    ~H"""
    <div>
      <div class="px-2 text-[10px] font-semibold uppercase tracking-wider text-[var(--incant-text-muted)]">{@title}</div>
      <div class="mt-1 space-y-0.5">
        <.link
          :for={item <- @items}
          patch={item.path}
          class={[
            "block rounded-md px-2 py-1.5 text-sm transition",
            item.id == @active_id && "bg-[var(--incant-bg-muted)] text-[var(--incant-text-highlighted)] shadow-[inset_2px_0_0_var(--incant-primary)]",
            item.id != @active_id && "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
          ]}
        >
          {item.label}
        </.link>
      </div>
    </div>
    """
  end

  attr(:surface, :any, required: true)
  attr(:env, :map, required: true)

  def render_surface(%{surface: %ResourceIndex{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class="space-y-3">
      <.filter_bar :if={@surface.filter_bar} filter_bar={@surface.filter_bar} env={@env} />
      <.resource_form :if={@surface.form} form={@surface.form} env={@env} />
      <.inspector :if={@surface.detail} inspector={@surface.detail} env={@env} />
      <.table table={@surface.table} env={@env} />
    </section>
    """
  end

  def render_surface(%{surface: %Dashboard{} = surface} = assigns) do
    assigns = assign(assigns, :surface, surface)

    ~H"""
    <section class="space-y-3">
      <.filter_bar :if={@surface.variables != []} filter_bar={List.first(@surface.regions)} env={@env} />
      <.widget_grid grid={Enum.find(@surface.regions, &match?(%WidgetGrid{}, &1))} />
    </section>
    """
  end

  def render_surface(%{surface: %Empty{context: %{authorization: {:error, reason}}}} = assigns) do
    assigns = assign(assigns, :message, authorization_message(reason))

    ~H"""
    <section class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-6 text-center">
      <p class="text-sm text-[var(--incant-text-muted)]">Access denied</p>
      <h2 class="mt-2 text-xl font-semibold tracking-tight">{@message}</h2>
    </section>
    """
  end

  def render_surface(assigns) do
    ~H"""
    """
  end

  attr(:filter_bar, FilterBar, required: true)
  attr(:env, :map, required: true)

  def filter_bar(assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <.form :let={_form} for={%{}} as={form_as(@filter_bar)} phx-change={change_event(@filter_bar)} class="grid gap-2 p-2 md:grid-cols-[minmax(12rem,1fr)_minmax(10rem,1fr)_minmax(14rem,1fr)_8rem]">
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

  attr(:table, Table, required: true)
  attr(:env, :map, required: true)

  def table(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <table class="min-w-full text-sm">
        <thead class="border-b border-[var(--incant-border)] bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]">
          <tr>
            <th :for={column <- @table.columns} class="h-8 px-3 font-medium">
              <button type="button" phx-click="incant:event" phx-value-op="sort" phx-value-target={column.id} class="inline-flex items-center gap-1 rounded px-1 py-0.5 hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]">
                {column.id}
                <span :if={sort_column(@table.sort) == column.id}>{sort_direction(@table.sort)}</span>
              </button>
            </th>
            <th :if={@table.row_actions != []} class="h-8 px-3 text-right font-medium">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-[var(--incant-border-muted)]">
          <tr :if={@table.rows == []}>
            <td colspan={length(@table.columns)} class="px-3 py-8 text-center text-sm text-[var(--incant-text-muted)]">{@table.empty_state}</td>
          </tr>
          <tr :for={row <- @table.rows} class="h-9 hover:bg-[var(--incant-bg-muted)]">
            <td :for={cell <- row.cells} class={cell_class(cell)}>
              <.table_cell cell={cell} row={row} env={@env} />
            </td>
            <td :if={@table.row_actions != []} class="px-3 py-1.5 text-right">
              <.row_actions row={row} actions={@table.row_actions} env={@env} />
            </td>
          </tr>
        </tbody>
      </table>
      <.pagination pagination={@table.pagination} />
    </div>
    """
  end

  def table_cell(assigns) do
    assigns = assign(assigns, :column, assigns.cell.source)

    ~H"""
    <.link :if={detail_link?(@env.context, @column, @row.source, @row.id)} patch={resource_detail_path(@env.base_path, @env.context.resource, @row.id)} class="font-medium text-[var(--incant-text-highlighted)] hover:underline">
      <.cell_value cell={@cell} />
    </.link>
    <.cell_value :if={!detail_link?(@env.context, @column, @row.source, @row.id)} cell={@cell} />
    """
  end

  attr(:cell, :map, required: true)

  def cell_value(assigns) do
    ~H"""
    <span :if={@cell.format == :badge} class="inline-flex h-5 items-center rounded-md bg-[var(--incant-bg-muted)] px-1.5 text-[11px] font-medium leading-none text-[var(--incant-text-toned)]">{@cell.value}</span>
    <span :if={@cell.format != :badge}>{@cell.display}</span>
    """
  end

  attr(:row, :map, required: true)
  attr(:actions, :list, required: true)
  attr(:env, :map, required: true)

  def row_actions(assigns) do
    ~H"""
    <div class="inline-flex items-center gap-1">
      <%= for action <- @actions, action_allowed?(@env.context, action, @row.source) do %>
        <.link :if={action.name == :edit && @row.id && form_enabled?(@env.context.resource)} patch={resource_edit_path(@env.base_path, @env.context.resource, @row.id)} class={action_class(action)}>
          {action_label(action)}
        </.link>
        <button :if={action.name != :edit || !form_enabled?(@env.context.resource)} type="button" class={action_class(action)} phx-click="incant:event" phx-value-op="row_action" phx-value-target={action.name} phx-value-value={@row.id} data-confirm={action.opts[:confirm] && "Are you sure?"}>
          {action_label(action)}
        </button>
      <% end %>
    </div>
    """
  end

  def pagination(%{pagination: %{total: total}} = assigns) when total > 0 do
    ~H"""
    <div class="flex h-10 items-center justify-between gap-3 border-t border-[var(--incant-border)] px-3 text-xs text-[var(--incant-text-muted)]">
      <div>Page {@pagination.page} of {@pagination.total_pages} · {@pagination.total} rows</div>
      <div class="flex items-center gap-1">
        <button type="button" phx-click="incant:event" phx-value-op="paginate" phx-value-value={@pagination.page - 1} disabled={@pagination.page <= 1} class="rounded-md border border-[var(--incant-border)] px-2 py-1 disabled:opacity-40 hover:bg-[var(--incant-bg-accented)]">Previous</button>
        <button type="button" phx-click="incant:event" phx-value-op="paginate" phx-value-value={@pagination.page + 1} disabled={@pagination.page >= @pagination.total_pages} class="rounded-md border border-[var(--incant-border)] px-2 py-1 disabled:opacity-40 hover:bg-[var(--incant-bg-accented)]">Next</button>
      </div>
    </div>
    """
  end

  def pagination(assigns) do
    ~H"""
    """
  end

  attr(:inspector, Inspector, required: true)
  attr(:env, :map, required: true)

  def inspector(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]">
      <div class="flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-3 py-2.5">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Detail</p>
          <h3 class="mt-1 text-base font-semibold tracking-tight text-[var(--incant-text-highlighted)]">{@inspector.title}</h3>
        </div>
        <.link patch={resource_path(@env.base_path, @env.context.resource)} class="text-xs font-medium text-[var(--incant-text-highlighted)] hover:underline">Back to list</.link>
      </div>
      <dl class="grid divide-y divide-[var(--incant-border-muted)] md:grid-cols-2 md:divide-x md:divide-y-0 xl:grid-cols-3">
        <div :for={field <- @inspector.fields} class="px-3 py-2.5">
          <dt class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{field.label}</dt>
          <dd class="mt-1 text-sm text-[var(--incant-text-highlighted)]">{field.display}</dd>
        </div>
      </dl>
    </div>
    """
  end

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
      <.form for={@phoenix_form} phx-change="validate_form" phx-submit="save_form" class="grid gap-3 p-3 md:grid-cols-2">
        <.form_control :for={field <- @form.fields} field={field} />
        <div class="md:col-span-2">
          <button type="submit" class="h-8 rounded-md bg-[var(--incant-primary)] px-3 text-sm font-medium text-[var(--incant-text-inverted)] transition hover:brightness-95">Save</button>
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

  attr(:grid, WidgetGrid, required: true)

  def widget_grid(assigns) do
    ~H"""
    <div class="grid grid-cols-1 gap-3 xl:grid-cols-12">
      <.widget :for={widget <- @grid.widgets} widget={widget} />
    </div>
    """
  end

  attr(:widget, :map, required: true)

  def widget(%{widget: %{type: :stat}} = assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3" style={widget_style(@widget)}>
      <p class="text-xs font-medium text-[var(--incant-text-muted)]">{@widget.title}</p>
      <div class="mt-2 text-2xl font-semibold tracking-tight text-[var(--incant-text-highlighted)]">
        <%= if @widget.error do %>
          <span class="text-base text-[var(--incant-error)]">{@widget.error}</span>
        <% else %>
          {@widget.display || "—"}
        <% end %>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :timeseries}} = assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Timeseries</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{@widget.title}</h3>
        </div>
        <span class="inline-flex h-5 items-center rounded-md border border-[var(--incant-border)] px-1.5 text-[11px] leading-none text-[var(--incant-text-muted)]">span {@widget.span || "auto"}</span>
      </div>
      <div :if={is_list(@widget.value) && @widget.value != []} class="mt-3 flex h-36 items-end gap-1.5 rounded-md bg-[var(--incant-bg-muted)] p-3">
        <div :for={point <- @widget.value} class="min-w-2 flex-1 rounded-sm bg-[var(--incant-primary)]" style={"height: #{bar_height(point, @widget.value)}%;"}></div>
      </div>
    </div>
    """
  end

  def widget(%{widget: %{type: :table}} = assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]" style={widget_style(@widget)}>
      <div class="flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] p-3">
        <div>
          <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">Table</p>
          <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{@widget.title}</h3>
        </div>
        <span class="inline-flex h-5 items-center rounded-md border border-[var(--incant-border)] px-1.5 text-[11px] leading-none text-[var(--incant-text-muted)]">span {@widget.span || "auto"}</span>
      </div>
      <table :if={is_list(@widget.value) && @widget.value != []} class="min-w-full text-sm">
        <thead class="bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]">
          <tr><th :for={column <- table_columns(@widget.value)} class="h-8 px-3 font-medium">{column}</th></tr>
        </thead>
        <tbody class="divide-y divide-[var(--incant-border-muted)]">
          <tr :for={row <- @widget.value} class="h-9"><td :for={column <- table_columns(@widget.value)} class="px-3 py-1.5 text-[var(--incant-text-toned)]">{Map.get(row, column)}</td></tr>
        </tbody>
      </table>
    </div>
    """
  end

  def widget(assigns) do
    ~H"""
    <div class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3" style={widget_style(@widget)}>
      <p class="text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]">{@widget.type}</p>
      <h3 class="mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]">{@widget.title}</h3>
    </div>
    """
  end

  defp form_as(%{id: "dashboard.variables"}), do: :var
  defp form_as(_filter_bar), do: :table

  defp change_event(%{id: "dashboard.variables"}), do: "dashboard_variables"
  defp change_event(_filter_bar), do: "table_state"

  defp control_name(%{role: :search}), do: "table[search]"
  defp control_name(%{role: :filter, name: name}), do: "table[filters][#{name}]"
  defp control_name(%{role: :dashboard_variable, name: name}), do: "var[#{name}]"
  defp control_name(%{name: name}), do: name

  defp control_name(%{role: :filter, name: name}, part), do: "table[filters][#{name}][#{part}]"
  defp control_name(%{role: :dashboard_variable, name: name}, part), do: "var[#{name}][#{part}]"

  defp input_class do
    "h-8 rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] transition focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]"
  end

  defp selected_values(nil), do: []
  defp selected_values(values) when is_list(values), do: Enum.map(values, &to_string/1)
  defp selected_values(value), do: [to_string(value)]

  defp map_value(value, key) when is_map(value), do: Map.get(value, key, "") |> input_value()
  defp map_value(_value, _key), do: ""

  defp input_value(%Date{} = date), do: Date.to_iso8601(date)
  defp input_value(value), do: value

  defp detail_link?(context, column, row, row_id) do
    column.opts[:link] && row_id &&
      Authorization.allowed?(
        context.admin,
        :view_row,
        context.actor,
        authorization_context(context, row)
      )
  end

  defp action_allowed?(context, %{name: :edit}, row) do
    if form_enabled?(context.resource) do
      Authorization.allowed?(
        context.admin,
        :edit,
        context.actor,
        authorization_context(context, row)
      )
    else
      Authorization.allowed?(
        context.admin,
        :run_action,
        context.actor,
        authorization_context(context, row, %{action: :edit})
      )
    end
  end

  defp action_allowed?(context, action, row) do
    Authorization.allowed?(
      context.admin,
      :run_action,
      context.actor,
      authorization_context(context, row, %{action: action.name})
    )
  end

  defp authorization_context(context, row, extra \\ %{}) do
    context |> Map.from_struct() |> Map.merge(%{row: row}) |> Map.merge(extra)
  end

  defp form_enabled?(resource), do: not is_nil(resource.repo) and not is_nil(resource.changeset)
  defp action_label(action), do: action.opts[:label] || humanize(action.name)

  defp action_class(action) do
    [
      "rounded-md px-1.5 py-1 text-xs transition",
      action.opts[:tone] == :danger &&
        "text-[var(--incant-text-muted)] hover:bg-[color-mix(in_oklab,var(--incant-error)_8%,transparent)] hover:text-[var(--incant-error)]",
      action.opts[:tone] != :danger &&
        "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
    ]
  end

  defp cell_class(cell) do
    [
      "px-3 py-1.5 text-[var(--incant-text-toned)]",
      cell.source.opts[:align] == :right && "text-right tabular-nums"
    ]
  end

  defp sort_column("-" <> column), do: column
  defp sort_column(column), do: column
  defp sort_direction("-" <> _column), do: "↓"
  defp sort_direction(_column), do: "↑"

  defp form_source(nil), do: %{}
  defp form_source(%{__struct__: Ecto.Changeset, params: params}) when is_map(params), do: params

  defp form_source(%{__struct__: Ecto.Changeset, changes: changes}) when is_map(changes),
    do: changes

  defp form_source(changeset), do: changeset

  defp form_eyebrow(:new), do: "New record"
  defp form_eyebrow(:edit), do: "Edit record"

  defp form_title(resource, record, :edit), do: Incant.Live.Rows.title(record, resource)
  defp form_title(resource, _record, :new), do: "New #{short_module(resource.module)}"

  defp form_back_path(env) do
    case {env.context.form_mode, Incant.Live.Rows.id(env.context.form_record)} do
      {:edit, nil} -> resource_path(env.base_path, env.context.resource)
      {:edit, id} -> resource_detail_path(env.base_path, env.context.resource, id)
      {:new, _id} -> resource_path(env.base_path, env.context.resource)
    end
  end

  defp form_input_type(%{source: %{type: type}}) when type in [:number, :date, :time],
    do: to_string(type)

  defp form_input_type(%{source: %{type: :datetime}}), do: "datetime-local"
  defp form_input_type(_field), do: "text"

  defp form_input_value(%{source: %{type: :datetime}, value: %DateTime{} = value}) do
    value |> DateTime.to_naive() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()
  end

  defp form_input_value(%{source: %{type: :datetime}, value: %NaiveDateTime{} = value}) do
    value |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()
  end

  defp form_input_value(%{source: %{type: :time}, value: %Time{} = value}),
    do: value |> Time.truncate(:second) |> Time.to_iso8601()

  defp form_input_value(%{value: nil}), do: nil
  defp form_input_value(%{value: %Decimal{} = value}), do: Decimal.to_string(value)
  defp form_input_value(%{value: value}), do: value

  defp widget_style(widget) do
    case widget.span do
      nil -> nil
      span -> "grid-column: span #{span} / span #{span};"
    end
  end

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

  defp authorization_message({:unauthorized, action}), do: "Not authorized to #{action}."
  defp authorization_message(reason) when is_atom(reason), do: "Not authorized: #{reason}."
  defp authorization_message(reason), do: "Not authorized: #{inspect(reason)}."

  defp short_module(nil), do: "Admin"
  defp short_module(module), do: module |> Module.split() |> List.last()

  defp humanize(value) do
    value
    |> to_string()
    |> String.replace(["_", "-"], " ")
    |> String.capitalize()
  end
end
