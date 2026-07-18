defmodule Incant.UI.Adapters.LiveView.AdapterTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest, only: [rendered_to_string: 1]

  test "renders dismissible info and error flash toasts" do
    html =
      %{flashes: [info: "Saved API key", error: "Unable to delete token"]}
      |> Incant.UI.Adapters.LiveView.flash_region()
      |> rendered_to_string()

    assert html =~ ~s(role="status")
    assert html =~ "Saved API key"
    assert html =~ "Unable to delete token"
    assert html =~ "Dismiss info notification"
    assert html =~ "Dismiss error notification"
    assert html =~ "data-incant-flash"
    assert html =~ "lv:clear-flash"
  end

  test "renders inline dashboard date-range presets with custom date fallback" do
    range = %Incant.UI.Controls.DateRange{
      id: "variables.range",
      name: "range",
      label: "Range",
      role: :dashboard_variable,
      value: "24h"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{variables: [range], env: env}
      |> Incant.UI.Adapters.LiveView.Controls.dashboard_variables()
      |> rendered_to_string()

    assert html =~ "1h"
    assert html =~ "24h"
    assert html =~ "7d"
    assert html =~ "30d"
    assert html =~ "Custom"
    assert html =~ ~s(data-incant-date-range-custom)
    assert html =~ ~s(name="var[range][from]")
    assert html =~ "hidden"
    assert html =~ "dashboard_variable_commit"

    custom_html =
      %{variables: [%{range | value: %{"from" => "2026-07-01", "to" => "2026-07-02"}}], env: env}
      |> Incant.UI.Adapters.LiveView.Controls.dashboard_variables()
      |> rendered_to_string()

    refute custom_html =~ ~s(data-incant-date-range-fields class="hidden")
    assert custom_html =~ ~s(value="2026-07-01")
  end

  test "renders resource filters as a compact builder instead of expanded fields" do
    control = %Incant.UI.Controls.Boolean{
      id: "filters.enabled",
      name: "enabled",
      label: "Enabled",
      role: :filter,
      value: "true",
      source: %{type: :boolean}
    }

    date_control = %Incant.UI.Controls.DateRange{
      id: "filters.created_at",
      name: "created_at",
      label: "Created at",
      role: :filter,
      value: %{},
      source: %{type: :date_range}
    }

    filter_bar = %Incant.UI.Regions.FilterBar{
      id: "resource.filters",
      filters: [control, date_control],
      state: Incant.UI.FilterState.new(nil, [control, date_control])
    }

    env =
      Incant.UI.Env.new(
        %Incant.Live.Context{base_path: "/admin", table_state: %{page_size: 25}},
        %{admin: nil}
      )

    html =
      %{filter_bar: filter_bar, env: env}
      |> Incant.UI.Adapters.LiveView.Controls.table_filter_bar()
      |> rendered_to_string()

    assert html =~ "Add filter"
    assert html =~ "Enabled"
    assert html =~ "Enabled</span>"
    assert html =~ ~s(phx-value-op="filter_clear")
    assert html =~ ~s(data-incant-filter-dialog)
    assert html =~ ~s(data-incant-filter-date-preset="7")
    assert html =~ ~s(type="date")
    refute html =~ ~s(name="table[page_size]")
  end

  test "renders autocomplete filters as controlled accessible comboboxes" do
    control = %Incant.UI.Controls.Combobox{
      id: "filters.model",
      name: "model",
      label: "Model",
      role: :filter,
      value: "",
      options: [
        %{label: "GPT-5.3 Codex Spark", value: "openai-codex/gpt-5.3-codex-spark"}
      ],
      source: %{type: :combobox}
    }

    filter_bar = %Incant.UI.Regions.FilterBar{
      id: "resource.filters",
      filters: [control],
      state: Incant.UI.FilterState.new(nil, [control])
    }

    env =
      Incant.UI.Env.new(
        %Incant.Live.Context{base_path: "/admin", table_state: %{page_size: 25}},
        %{admin: nil}
      )

    html =
      %{filter_bar: filter_bar, env: env}
      |> Incant.UI.Adapters.LiveView.Controls.table_filter_bar()
      |> rendered_to_string()

    assert html =~ ~s(role="combobox")
    assert html =~ ~s(role="listbox")
    assert html =~ ~s(role="option")
    assert html =~ ~s(aria-controls="incant-filter-model-options")
    assert html =~ ~s(autocomplete="new-password")
    assert html =~ ~s(data-value="openai-codex/gpt-5.3-codex-spark")
    assert html =~ "GPT-5.3 Codex Spark"
    refute html =~ "<datalist"
    refute html =~ ~s(list="incant-filter-model-options")
  end

  test "renders table column labels instead of raw ids" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "total_spend_usd", label: "Spend", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "input_tokens", label: "Input tokens", sortable: true}
      ],
      rows: [],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ ">\n            Spend\n"
    assert html =~ ">\n            Input tokens\n"
    refute html =~ ">\n            total_spend_usd\n"
    refute html =~ ">\n            input_tokens\n"
  end

  test "applies semantic column priority at mobile breakpoints" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{
          id: "name",
          label: "Name",
          priority: :primary,
          sortable: false
        },
        %Incant.UI.Regions.Table.Column{
          id: "status",
          label: "Status",
          priority: :secondary,
          sortable: false
        },
        %Incant.UI.Regions.Table.Column{
          id: "audit",
          label: "Audit",
          priority: :tertiary,
          sortable: false
        }
      ],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "name",
              display: "Ada",
              source: %{opts: [priority: :primary]}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "status",
              display: "Active",
              source: %{opts: [priority: :secondary]}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "audit",
              display: "Today",
              source: %{opts: [priority: :tertiary]}
            }
          ]
        }
      ],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ "hidden sm:table-cell"
    assert html =~ "hidden lg:table-cell"
  end

  test "links one intentional data cell when a row detail is available" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "name", label: "Name", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "status", label: "Status", sortable: true}
      ],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          detail: %{},
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "name",
              value: "Ada",
              display: "Ada",
              source: %{opts: []}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "status",
              value: "active",
              display: "active",
              source: %{opts: []}
            }
          ]
        }
      ],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    context = %Incant.Live.Context{base_path: "/admin", resource: %{id: "user"}}
    env = Incant.UI.Env.new(context, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert length(Regex.scan(~r/href="\/admin\/resources\/user\/row-1"/, html)) == 1
    refute html =~ "cursor-pointer"
  end

  test "renders boolean and identifier cells with semantic table treatment" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "enabled", label: "Enabled", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "key_id", label: "Key", sortable: true}
      ],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "enabled",
              value: true,
              display: "Yes",
              format: :boolean,
              source: %{opts: []}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "key_id",
              value: "27dca8e9-9d57",
              display: "27dca8e9…",
              format: :id,
              source: %{opts: []}
            }
          ]
        }
      ],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    refute html =~ "●"
    assert html =~ "Yes"
    assert html =~ "font-mono text-xs"
    assert html =~ ~s(title="27dca8e9-9d57")
  end

  test "truncates long and text-format table cells with hover titles" do
    long_text = String.duplicate("long message ", 20)

    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "message", label: "Message", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "notes", label: "Notes", sortable: true}
      ],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "message",
              value: long_text,
              display: long_text,
              format: nil,
              source: %{opts: []}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "notes",
              value: "short text",
              display: "short text",
              format: :text,
              source: %{opts: [format: :text]}
            }
          ]
        }
      ],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ "max-w-[28rem]"
    assert html =~ "truncate"
    assert html =~ ~s(title="#{String.slice(long_text, 0, 200)}")
    assert html =~ ~s(title="short text")
  end

  test "renders sensitive table cells as redacted badges without cleartext titles" do
    table = %Incant.UI.Regions.Table{
      columns: [%Incant.UI.Regions.Table.Column{id: "token", label: "Token", sortable: true}],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "token",
              value: "[redacted]",
              display: "[redacted]",
              format: nil,
              source: %{opts: [redacted: true]}
            }
          ]
        }
      ],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ "max-w-[28rem]"
    assert html =~ ~s(title="Hidden")
    assert html =~ "Hidden"
    assert html =~ "border border-[var(--incant-border)]"
    refute html =~ "sk-secret"
  end

  test "renders action confirm text from boolean or custom messages" do
    table = %Incant.UI.Regions.Table{
      columns: [%Incant.UI.Regions.Table.Column{id: "name", label: "Name", sortable: true}],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "name",
              value: "Ada",
              display: "Ada",
              source: %{opts: []}
            }
          ]
        }
      ],
      row_actions: [
        %Incant.Table.Action{name: :delete, opts: [confirm: true]},
        %Incant.Table.Action{name: :disable, opts: [confirm: "Disable this token?"]},
        %Incant.Table.Action{name: :view, opts: []}
      ],
      bulk_actions: [%Incant.Table.Action{name: :delete_selected, opts: [confirm: true]}],
      page_actions: [%Incant.Table.Action{name: :resync, opts: [confirm: "Resync now?"]}],
      selection: %Incant.UI.Regions.Table.Selection{enabled: true, selected_ids: ["row-1"]},
      empty_state: "No rows"
    }

    env =
      Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin", resource: %{id: "user"}}, %{
        admin: nil
      })

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ ~s(data-incant-confirm=)
    assert html =~ ~s(&quot;Are you sure you want to delete?&quot;)
    assert html =~ ~s(&quot;title&quot;:&quot;Delete?&quot;)
    assert html =~ ~s(&quot;destructive&quot;:false)
    assert html =~ ~s(phx-disable-with="Delete…")
    assert html =~ ~s(&quot;Disable this token?&quot;)
    assert html =~ ~s(&quot;Resync now?&quot;)
    refute html =~ ~s(data-confirm=)
  end

  test "renders operator-friendly empty table copy" do
    table = %Incant.UI.Regions.Table{
      columns: [%Incant.UI.Regions.Table.Column{id: "name", label: "Name", sortable: true}],
      rows: [],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No results. Try adjusting or clearing the filters."
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ "No results. Try adjusting or clearing the filters."
    refute html =~ "Add a resource index callback"
    refute html =~ "Developer hint:"
  end

  test "renders empty table developer hints only in debug mode" do
    table = %Incant.UI.Regions.Table{
      columns: [%Incant.UI.Regions.Table.Column{id: "name", label: "Name", sortable: true}],
      rows: [],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No results. Try adjusting or clearing the filters."
    }

    env = %Incant.UI.Env{debug: true, base_path: "/admin", context: %Incant.Live.Context{}}

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ "No results. Try adjusting or clearing the filters."
    assert html =~ "Developer hint: verify the resource index callback"
  end

  test "renders stat card deltas and dashboard grid columns" do
    grid = %Incant.UI.Regions.WidgetGrid{
      columns: 10,
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :requests,
          type: :stat,
          title: "Requests",
          display: "1,234",
          delta: -0.125,
          span: 2
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "--incant-grid-columns: 10"
    assert html =~ "Requests"
    assert html =~ "1,234"
    assert html =~ "-12.5% vs previous"
    assert html =~ "text-[var(--incant-error)]"
    assert html =~ "text-3xl"
    refute html =~ "col-span-"
  end

  test "renders dashboard table widgets with source column metadata" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :usage,
          type: :table,
          title: "Usage",
          value: [%{cost: 1.0, enabled: false, model: "gpt", requests: 2}],
          span: 4,
          source: %Incant.Dashboard.Widget{
            id: :usage,
            type: :table,
            opts: [
              columns: [
                %Incant.Dashboard.Column{name: :model, opts: [label: "Model"]},
                %Incant.Dashboard.Column{
                  name: :requests,
                  opts: [label: "Requests", format: :number]
                },
                %Incant.Dashboard.Column{
                  name: :enabled,
                  opts: [label: "Enabled", format: :boolean]
                },
                %Incant.Dashboard.Column{name: :cost, opts: [label: "Cost", format: :money]}
              ]
            ]
          }
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "Usage"
    assert html =~ ~r/Model.*Requests.*Enabled.*Cost/s
    assert html =~ ~r/gpt.*2.*No.*\$1.00/s
    assert html =~ ~s(<th class="h-8 px-3 font-medium text-right">Requests</th>)
    assert html =~ ~s(<th class="h-8 px-3 font-medium text-right">Cost</th>)

    assert html =~
             ~S|<td class="px-3 py-1.5 text-[var(--incant-text-toned)] text-right tabular-nums">$1.00</td>|
  end

  test "caps dashboard table previews and preserves responsive column metadata" do
    rows = Enum.map(1..12, &%{model: "model-#{&1}", count: &1})

    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :usage,
          type: :table,
          title: "Usage",
          value: rows,
          span: 7,
          source: %Incant.Dashboard.Widget{
            id: :usage,
            type: :table,
            opts: [
              preview_rows: 3,
              columns: [
                %Incant.Dashboard.Column{name: :model, opts: [priority: :primary]},
                %Incant.Dashboard.Column{name: :count, opts: [priority: :secondary]}
              ]
            ]
          }
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "model-1"
    assert html =~ "model-3"
    refute html =~ "model-4"
    assert html =~ "Showing 3 of 12 rows"
    assert html =~ "hidden sm:table-cell"
    assert html =~ "--incant-widget-span: 7"
    refute html =~ "grid-column: span 7"
  end

  test "right-aligns resource table cells from explicit or formatted metadata" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "name", label: "Name", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "cost", label: "Cost", sortable: true, format: :money}
      ],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "name",
              value: "Ada",
              display: "Ada",
              source: %Incant.Table.Column{name: :name, opts: []}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "cost",
              value: 1.0,
              display: "$1.00",
              format: :money,
              source: %Incant.Table.Column{name: :cost, opts: [format: :money]}
            }
          ]
        }
      ],
      row_actions: [],
      selection: %Incant.UI.Regions.Table.Selection{enabled: false},
      empty_state: "No rows"
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ ~s(<th class="h-8 px-3 font-medium text-right" aria-sort="none">)
    assert html =~ "w-full"
    assert html =~ "justify-end"

    assert html =~
             ~S|<td class="px-3 py-1.5 text-[var(--incant-text-toned)] text-right tabular-nums">|

    assert html =~ "$1.00"
  end

  test "renders dashboard table widget empty, loading, and error states" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :empty_usage,
          type: :table,
          title: "Empty usage",
          value: [],
          span: 4,
          source: %Incant.Dashboard.Widget{
            id: :empty_usage,
            type: :table,
            opts: [
              columns: [
                %Incant.Dashboard.Column{name: :service, opts: [label: "Service"]},
                %Incant.Dashboard.Column{name: :count, opts: [label: "Count", format: :number]}
              ]
            ]
          }
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :loading_usage,
          type: :table,
          title: "Loading usage",
          value: nil,
          loading: true,
          span: 4,
          source: %Incant.Dashboard.Widget{id: :loading_usage, type: :table, opts: []}
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :error_usage,
          type: :table,
          title: "Error usage",
          value: {:error, :boom},
          error: :boom,
          span: 4,
          source: %Incant.Dashboard.Widget{id: :error_usage, type: :table, opts: []}
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ ~r/Service.*Count.*No rows to display\./s
    assert html =~ "Loading…"
    assert html =~ "Unable to load widget."
    refute html =~ "boom"
  end

  test "renders dashboard timeseries empty, loading, and error states" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :empty_series,
          type: :timeseries,
          title: "Empty series",
          value: [],
          span: 4
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :loading_series,
          type: :timeseries,
          title: "Loading series",
          value: nil,
          loading: true,
          span: 4
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :error_series,
          type: :timeseries,
          title: "Error series",
          value: {:error, :boom},
          error: :boom,
          span: 4
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "No data to display."
    assert html =~ "Loading…"
    assert html =~ "Unable to load widget."
    refute html =~ "boom"
  end

  test "renders dependency-free SVG bars and line charts" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :requests,
          type: :timeseries,
          title: "Requests",
          value: [
            %Incant.UI.Regions.Chart.Point{label: "10:00", value: 2},
            %Incant.UI.Regions.Chart.Point{label: "11:00", value: 6}
          ],
          span: 5
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :spend,
          type: :chart,
          title: "Spend",
          value: [
            %Incant.UI.Regions.Chart.Point{label: "10:00", value: 1},
            %Incant.UI.Regions.Chart.Point{label: "11:00", value: 3}
          ],
          span: 5,
          chart: %Incant.UI.Regions.Chart{id: :spend, type: :line}
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "<rect"
    assert html =~ "<polyline"
    assert html =~ "<polygon"
    assert html =~ "chart-gradient-spend"
    assert html =~ "10:00"
    assert html =~ "11:00"
    refute html =~ "chart_placeholder"
  end

  test "renders dashboard table widgets with sorted fallback columns" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :usage,
          type: :table,
          title: "Usage",
          value: [%{zeta: 1, alpha: 2}],
          span: 4
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ ~r/Alpha.*Zeta/s
    assert html =~ ~r/2.*1/s
  end

  test "does not render dashboard widget span debug badges" do
    grid = %Incant.UI.Regions.WidgetGrid{
      widgets: [
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :requests_over_time,
          type: :timeseries,
          title: "Requests over time",
          value: [
            %Incant.UI.Regions.Chart.Point{value: 1},
            %Incant.UI.Regions.Chart.Point{value: 2},
            %Incant.UI.Regions.Chart.Point{value: 3}
          ],
          span: 8
        },
        %Incant.UI.Regions.WidgetGrid.Widget{
          id: :recent_requests,
          type: :table,
          title: "Recent requests",
          value: [%{model: "gpt", count: 1}],
          span: 4
        }
      ]
    }

    html =
      %{grid: grid}
      |> Incant.UI.Adapters.LiveView.Dashboard.widget_grid()
      |> rendered_to_string()

    assert html =~ "Requests over time"
    assert html =~ "Recent requests"
    refute html =~ ">span 8<"
    refute html =~ ">span 4<"
    refute html =~ ">span auto<"
  end

  test "renders nav links as full LiveView navigation links" do
    nav = %Incant.UI.Regions.Nav{
      active_id: "dashboard.operations",
      items: [
        %Incant.UI.Regions.Nav.Item{
          id: "dashboard.operations",
          label: "Operations",
          group: :dashboards,
          path: "/llm_proxy/dashboards/operations"
        },
        %Incant.UI.Regions.Nav.Item{
          id: "resource.api_key",
          label: "API Keys",
          group: :resources,
          path: "/llm_proxy/resources/api_key"
        }
      ]
    }

    html =
      %{nav: nav}
      |> Incant.UI.Adapters.LiveView.nav()
      |> rendered_to_string()

    assert html =~ ~s(href="/llm_proxy/resources/api_key")
    assert html =~ ~s(aria-current="page")
    refute html =~ "Datasets"
    refute html =~ ~s(data-phx-link)
  end

  test "renders linked breadcrumb parents with the current page highlighted" do
    html =
      %{
        items: [
          %{label: "Incant", path: "/"},
          %{label: "llm_proxy", path: "/llm_proxy"},
          %{label: "Resources", path: "/llm_proxy/resources/api_key"},
          %{label: "API Keys", path: nil}
        ]
      }
      |> Incant.UI.Adapters.LiveView.breadcrumbs()
      |> rendered_to_string()

    assert html =~ ~s(aria-label="Breadcrumb")
    assert html =~ ~s(href="/")
    assert html =~ ~s(href="/llm_proxy")
    assert html =~ ~s(href="/llm_proxy/resources/api_key")
    assert html =~ ~s(aria-current="page")
    assert html =~ "API Keys"
  end

  test "renders accessible sortable headers, selection checkboxes, density, and pagination range" do
    table = %Incant.UI.Regions.Table{
      columns: [
        %Incant.UI.Regions.Table.Column{id: "name", label: "Name", sortable: true},
        %Incant.UI.Regions.Table.Column{id: "status", label: "Status", sortable: false}
      ],
      rows: [
        %Incant.UI.Regions.Table.Row{
          id: "row-1",
          source: %{},
          cells: [
            %Incant.UI.Regions.Table.Cell{
              column: "name",
              value: "Ada",
              display: "Ada",
              source: %{opts: []}
            },
            %Incant.UI.Regions.Table.Cell{
              column: "status",
              value: "active",
              display: "active",
              source: %{opts: []}
            }
          ]
        }
      ],
      sort: "-name",
      pagination: %{page: 2, page_size: 25, total: 31, total_pages: 2},
      selection: %Incant.UI.Regions.Table.Selection{enabled: true, selected_ids: ["row-1"]},
      empty_state: "No rows",
      density: :comfortable
    }

    env = Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{admin: nil})

    html =
      %{table: table, env: env}
      |> Incant.UI.Adapters.LiveView.Table.table()
      |> rendered_to_string()

    assert html =~ ~s(aria-sort="descending")
    assert html =~ ~s(aria-label="Select all rows on this page")
    assert html =~ ~s(phx-value-op="row_select_all")
    assert html =~ ~s(aria-label="Select row row-1")
    assert html =~ "h-12"
    assert html =~ "26–31 of 31"
    assert html =~ ~s(name="table[page_size]")
    assert html =~ ~s(aria-label="Rows per page")
    assert html =~ ~s(aria-label="First page")
    assert html =~ ~s(aria-label="Previous page")
    assert html =~ ~s(aria-label="Page number")
    assert html =~ ~s(max="2")
    assert html =~ ">of 2</span>"
    assert html =~ ~s(aria-label="Next page")
    assert html =~ ~s(aria-label="Last page")
    refute html =~ ~s(phx-value-target="status")
  end

  test "uses the canonical service title in rendered breadcrumbs" do
    contract = %Incant.Admin.Contract{service: :llm_proxy, opts: %{title: "LLM Proxy"}}
    entry = %Incant.Service.Entry{contract: contract}

    context = %Incant.Live.Context{
      base_path: "/llm_proxy",
      section: "resources",
      resources: [],
      datasets: [],
      dashboards: [],
      session: %Incant.Service.Session{entry: entry}
    }

    document = Incant.UI.Document.from_context(context)
    env = Incant.UI.Env.new(context, %{admin: nil})
    html = document |> Incant.UI.render(env) |> rendered_to_string()

    assert html =~ "LLM Proxy"
    refute html =~ ">llm_proxy<"
  end

  test "renders service index links as absolute paths" do
    services = [
      %Incant.Web.API.ServiceSummary{
        id: "llm_proxy",
        key: "llm_proxy",
        service: "llm_proxy",
        version: "1",
        surfaces: %Incant.Web.API.SurfaceCounts{resources: 4, datasets: 0, dashboards: 1}
      }
    ]

    context = %Incant.Live.Context{
      base_path: "/",
      section: "services",
      resources: [],
      datasets: [],
      dashboards: [],
      services: services
    }

    document = Incant.UI.Document.from_context(context)
    env = Incant.UI.Env.new(context, %{admin: nil})

    html = document |> Incant.UI.render(env) |> rendered_to_string()

    assert html =~ ~s(href="/llm_proxy")
    refute html =~ ~s(data-phx-link)
    refute html =~ ~s(href="llm_proxy")
    assert html =~ "4"
    assert html =~ "Resources"
  end

  test "renders reveal dialog for one-time action secrets" do
    context = %Incant.Live.Context{
      base_path: "/",
      section: "services",
      resources: [],
      datasets: [],
      dashboards: [],
      services: []
    }

    document = Incant.UI.Document.from_context(context)

    env =
      Incant.UI.Env.new(context, %{
        admin: nil,
        reveal: %Incant.ActionResult.Reveal{
          title: "Created docgen",
          value: "sk-proxy-secret-123",
          description: "Copy this value now. You won't be able to see it again."
        }
      })

    html = document |> Incant.UI.render(env) |> rendered_to_string()

    assert html =~ "Created docgen"
    assert html =~ "sk-proxy-secret-123"
    assert html =~ "won&#39;t be able to see it again."
    assert html =~ ~s(data-incant-reveal-dialog)
    assert html =~ ~s(data-incant-reveal-copy)
    assert html =~ ~s(phx-value-op="reveal_dismiss")
  end

  test "hides reveal dialog without a reveal assign" do
    context = %Incant.Live.Context{
      base_path: "/",
      section: "services",
      resources: [],
      datasets: [],
      dashboards: [],
      services: []
    }

    document = Incant.UI.Document.from_context(context)
    env = Incant.UI.Env.new(context, %{admin: nil})

    html = document |> Incant.UI.render(env) |> rendered_to_string()

    refute html =~ ~s(data-incant-reveal-dialog)
  end
end
