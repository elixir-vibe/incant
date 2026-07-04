defmodule Incant.UI.Adapters.LiveView.Theme do
  @moduledoc false

  alias Incant.UI.Adapters.LiveView.Recipe
  alias Incant.UI.Adapters.LiveView.Recipe.CompoundVariant

  def slot(name, slot \\ :base, opts \\ []) do
    name |> recipe() |> Recipe.slot(slot, opts)
  end

  def recipe(:shell) do
    %Recipe{
      slots: %{
        root: "min-h-screen bg-[var(--incant-bg)] text-[var(--incant-text)] antialiased",
        sidebar:
          "fixed inset-y-0 left-0 hidden w-60 border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] lg:block",
        brand: "border-b border-[var(--incant-border-muted)] px-4 py-4",
        brand_mark:
          "text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--incant-primary)]",
        brand_title: "mt-1.5 text-sm font-medium text-[var(--incant-text-highlighted)]",
        main: "min-w-0 lg:pl-60",
        topbar:
          "sticky top-0 z-10 border-b border-[var(--incant-border)] bg-[color-mix(in_oklab,var(--incant-bg-elevated)_94%,transparent)] px-5 backdrop-blur",
        topbar_inner: "mx-auto flex h-12 max-w-[1180px] items-center justify-between gap-3",
        chrome_count: "hidden shrink-0 text-xs text-[var(--incant-text-muted)] md:block",
        body: "mx-auto max-w-[1180px] p-4 lg:p-5"
      }
    }
  end

  def recipe(:nav_item) do
    %Recipe{
      slots: %{
        base:
          "block rounded-md px-2.5 py-1.5 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]"
      },
      variants: %{
        active: %{
          true => %{
            base: "bg-[var(--incant-bg-muted)] font-medium text-[var(--incant-text-highlighted)]"
          },
          false => %{
            base:
              "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
          }
        }
      },
      default_variants: %{active: false}
    }
  end

  def recipe(:page_header) do
    %Recipe{
      slots: %{
        root:
          "mb-4 flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] pb-4",
        eyebrow: "text-xs text-[var(--incant-text-muted)]",
        title: "mt-1 text-2xl font-semibold tracking-tight text-[var(--incant-text-highlighted)]",
        actions: "shrink-0"
      }
    }
  end

  def recipe(:dataset) do
    %Recipe{
      slots: %{
        drilldowns: "flex flex-wrap items-center gap-2"
      }
    }
  end

  def recipe(:nav) do
    %Recipe{
      slots: %{
        root: "space-y-5 px-3 py-4",
        group_label:
          "px-2 text-[10px] font-semibold uppercase tracking-wider text-[var(--incant-text-muted)]",
        group_items: "mt-1 space-y-0.5"
      }
    }
  end

  def recipe(:debug) do
    %Recipe{
      slots: %{
        pre:
          "rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-muted)] p-3 text-xs text-[var(--incant-text-muted)]"
      }
    }
  end

  def recipe(:surface) do
    %Recipe{
      slots: %{
        stack: "space-y-4",
        index: "grid items-start gap-4 xl:grid-cols-[minmax(0,1fr)_18rem]",
        primary: "min-w-0 space-y-3",
        aside: "space-y-3 xl:sticky xl:top-16"
      }
    }
  end

  def recipe(:panel) do
    %Recipe{
      slots: %{
        root:
          "overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]",
        header:
          "flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-4 py-3",
        body: "p-4",
        form_actions: "flex items-center gap-3 md:col-span-2",
        title: "text-sm text-[var(--incant-text-muted)]",
        empty_title: "mt-2 text-xl font-semibold tracking-tight"
      },
      variants: %{
        kind: %{
          filter: %{
            root: "rounded-lg",
            body: "space-y-3 p-3",
            title: "text-lg font-semibold tracking-tight text-[var(--incant-text-highlighted)]"
          },
          form: %{root: "max-w-[880px]", body: "grid gap-4 md:grid-cols-2"},
          table: %{root: "min-w-0"},
          inspector: %{root: "max-w-[980px]"},
          empty: %{root: "p-6 text-center"}
        }
      },
      default_variants: %{kind: :default}
    }
  end

  def recipe(:field) do
    %Recipe{
      slots: %{
        root:
          "grid gap-1 text-xs font-medium uppercase tracking-wide text-[var(--incant-text-muted)]",
        group: "space-y-3",
        inline: "grid grid-cols-2 gap-2",
        input:
          "h-8 w-full rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm font-normal normal-case tracking-normal text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] transition-colors focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]",
        error: "text-xs font-normal normal-case tracking-normal text-[var(--incant-error)]"
      },
      variants: %{
        span: %{
          full: %{root: "md:col-span-2"},
          auto: %{}
        },
        style: %{
          code: %{input: "font-mono"},
          default: %{}
        },
        height: %{
          tall: %{input: "min-h-20"},
          default: %{}
        }
      },
      default_variants: %{span: :auto, style: :default, height: :default}
    }
  end

  def recipe(:button) do
    %Recipe{
      slots: %{
        base:
          "inline-flex h-8 items-center justify-center rounded-md px-3 text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)] disabled:pointer-events-none disabled:opacity-40"
      },
      variants: %{
        variant: %{
          primary: %{
            base:
              "bg-[var(--incant-primary)] text-[var(--incant-text-inverted)] hover:brightness-95"
          },
          ghost: %{
            base:
              "text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
          },
          outline: %{
            base:
              "border border-[var(--incant-border)] text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)]"
          }
        },
        size: %{
          xs: %{base: "h-7 px-2 text-xs"},
          sm: %{base: "h-8 px-3 text-sm"}
        }
      },
      compound_variants: [
        %CompoundVariant{match: %{variant: :ghost, size: :xs}, classes: %{base: "px-1.5"}}
      ],
      default_variants: %{variant: :outline, size: :sm}
    }
  end

  def recipe(:badge) do
    %Recipe{
      slots: %{
        base: "inline-flex h-5 items-center rounded-md px-1.5 text-[11px] leading-none"
      },
      variants: %{
        variant: %{
          soft: %{base: "bg-[var(--incant-bg-muted)] font-medium text-[var(--incant-text-toned)]"},
          outline: %{base: "border border-[var(--incant-border)] text-[var(--incant-text-muted)]"}
        }
      },
      default_variants: %{variant: :outline}
    }
  end

  def recipe(:table) do
    %Recipe{
      slots: %{
        toolbar:
          "flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] px-3 py-2",
        toolbar_group: "flex items-center gap-1.5",
        toolbar_hint: "text-xs text-[var(--incant-text-muted)]",
        checkbox_cell: "w-8 px-3 py-1.5",
        checkbox:
          "h-3.5 w-3.5 rounded border-[var(--incant-border)] text-[var(--incant-primary)] focus:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        viewport: "overflow-x-auto",
        root: "min-w-full text-sm",
        head:
          "border-b border-[var(--incant-border)] bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]",
        header_cell: "h-8 px-3 font-medium",
        sort_button:
          "inline-flex items-center gap-1 rounded px-1 py-0.5 hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        body: "divide-y divide-[var(--incant-border-muted)]",
        row: "h-9 hover:bg-[var(--incant-bg-muted)]",
        cell: "px-3 py-1.5 text-[var(--incant-text-toned)]",
        cell_content: "block",
        empty: "px-3 py-8 text-center text-sm text-[var(--incant-text-muted)]",
        actions: "px-3 py-1.5 text-right",
        action_group: "inline-flex items-center gap-1",
        link: "font-medium text-[var(--incant-text-highlighted)] hover:underline",
        pagination:
          "flex h-10 items-center justify-between gap-3 border-t border-[var(--incant-border)] px-3 text-xs text-[var(--incant-text-muted)]",
        pagination_actions: "flex items-center gap-1"
      },
      variants: %{
        align: %{
          right: %{header_cell: "text-right", cell: "text-right tabular-nums"},
          left: %{}
        },
        truncate: %{
          true => %{cell: "max-w-[28rem]", cell_content: "truncate"},
          false => %{}
        }
      },
      default_variants: %{align: :left, truncate: false}
    }
  end

  def recipe(:inspector) do
    %Recipe{
      slots: %{
        list:
          "grid divide-y divide-[var(--incant-border-muted)] md:grid-cols-2 md:divide-x md:divide-y-0 xl:grid-cols-3",
        item: "px-4 py-3",
        label: "text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]",
        value: "mt-1 text-sm text-[var(--incant-text-highlighted)]"
      }
    }
  end

  def recipe(:widget_grid) do
    %Recipe{
      slots: %{
        root: "grid grid-cols-1 gap-3 xl:grid-cols-12"
      }
    }
  end

  def recipe(:widget) do
    %Recipe{
      slots: %{
        root:
          "rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3",
        framed:
          "overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]",
        title_row: "flex items-center justify-between gap-3",
        header:
          "flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] p-3",
        eyebrow:
          "text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]",
        title: "mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]",
        stat_label: "text-xs font-medium text-[var(--incant-text-muted)]",
        stat_value:
          "mt-2 text-2xl font-semibold tracking-tight text-[var(--incant-text-highlighted)]",
        error: "text-base text-[var(--incant-error)]",
        message: "p-3 text-sm text-[var(--incant-text-muted)]",
        message_error: "p-3 text-sm text-[var(--incant-error)]",
        chart: "mt-3 flex h-36 items-end gap-1.5 rounded-md bg-[var(--incant-bg-muted)] p-3",
        chart_placeholder: "flex min-h-full w-full flex-col justify-end gap-3",
        chart_line: "h-16 rounded-[50%] border-t-2 border-[var(--incant-primary)] opacity-80",
        chart_axis:
          "flex items-center justify-between text-[11px] text-[var(--incant-text-muted)]",
        bar: "min-w-2 flex-1 rounded-sm bg-[var(--incant-primary)]"
      }
    }
  end
end
