defmodule Incant.Dashboard.Scope do
  @moduledoc false

  use DSL

  alias Incant.Dashboard.{Column, Widget}

  scope :dashboard do
    accepts(:widget, into: :widgets)
  end

  scope :table_widget do
    requires(:dashboard)
    accepts(:column, into: :columns)
  end

  def start_dashboard do
    push_dashboard(%{widgets: []})
  end

  def finish_dashboard do
    pop_dashboard()
  end

  def add_widget(id, type, opts) do
    attach(:widget, %Widget{id: id, type: type, opts: opts})
  end

  def start_table_widget(id, opts) do
    push_table_widget(%{id: id, opts: opts, columns: []})
  end

  def finish_table_widget do
    table = pop_table_widget()
    opts = Keyword.put(table.opts, :columns, table.columns)
    attach(:widget, %Widget{id: table.id, type: :table, opts: opts})
  end

  def add_column(name, opts) do
    attach(:column, %Column{name: name, opts: opts})
  end
end
