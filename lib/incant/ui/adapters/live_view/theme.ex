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
          "fixed inset-y-0 left-0 z-40 flex w-64 -translate-x-full flex-col border-r border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] transition-transform duration-200 lg:w-60 lg:translate-x-0",
        sidebar_backdrop: "fixed inset-0 z-30 hidden bg-black/30 backdrop-blur-[1px] lg:hidden",
        brand: "border-b border-[var(--incant-border-muted)] px-4 py-4",
        brand_mark:
          "text-[11px] font-semibold uppercase tracking-[0.24em] text-[var(--incant-primary)]",
        brand_title: "mt-1 text-base font-semibold text-[var(--incant-text-highlighted)]",
        main: "min-w-0 lg:pl-60",
        topbar:
          "sticky top-0 z-20 border-b border-[var(--incant-border)] bg-[color-mix(in_oklab,var(--incant-bg-elevated)_94%,transparent)] px-4 backdrop-blur lg:px-5",
        topbar_inner: "mx-auto flex h-12 max-w-[1180px] items-center justify-between gap-3",
        breadcrumb: "flex min-w-0 items-center gap-1.5 text-sm",
        breadcrumb_muted: "truncate text-[var(--incant-text-muted)]",
        breadcrumb_current: "truncate font-medium text-[var(--incant-text-highlighted)]",
        breadcrumb_separator: "text-[var(--incant-text-dimmed)]",
        topbar_actions: "ml-auto flex items-center gap-1",
        icon_button:
          "inline-flex h-8 w-8 items-center justify-center rounded-md text-[var(--incant-text-muted)] transition-colors hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        mobile_nav_toggle: "lg:hidden",
        body: "mx-auto max-w-[1180px] p-4 lg:p-5"
      }
    }
  end

  def recipe(:toast) do
    %Recipe{
      slots: %{
        region:
          "pointer-events-none fixed right-4 top-4 z-50 flex w-full max-w-sm flex-col gap-2",
        root:
          "pointer-events-auto flex items-start gap-3 rounded-lg border px-3 py-2.5 text-sm shadow-lg transition-opacity",
        message: "flex-1 leading-5",
        close:
          "-mr-1 inline-flex h-6 w-6 shrink-0 items-center justify-center rounded text-current/70 hover:bg-black/5 hover:text-current focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-current/30"
      },
      variants: %{
        level: %{
          info: %{
            root:
              "border-[color-mix(in_oklab,var(--incant-success)_32%,var(--incant-border))] bg-[color-mix(in_oklab,var(--incant-success)_10%,var(--incant-bg-elevated))] text-[var(--incant-text-highlighted)]"
          },
          error: %{
            root:
              "border-[color-mix(in_oklab,var(--incant-error)_38%,var(--incant-border))] bg-[color-mix(in_oklab,var(--incant-error)_10%,var(--incant-bg-elevated))] text-[var(--incant-text-highlighted)]"
          }
        }
      },
      default_variants: %{level: :info}
    }
  end

  def recipe(:nav_item) do
    %Recipe{
      slots: %{
        base:
          "block rounded-r-md border-l-[3px] border-transparent px-2.5 py-2 text-sm transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]"
      },
      variants: %{
        active: %{
          true => %{
            base:
              "border-l-[var(--incant-primary)] bg-[var(--incant-bg-muted)] font-medium text-[var(--incant-text-highlighted)]"
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

  def recipe(:dashboard) do
    %Recipe{
      slots: %{
        variables: "-mt-2 border-b border-[var(--incant-border-muted)] pb-3",
        variable_form: "flex flex-wrap items-end gap-3",
        variable_label:
          "text-[10px] font-semibold uppercase tracking-wide text-[var(--incant-text-muted)]",
        date_range: "flex flex-wrap items-center gap-2",
        preset_group: "flex items-center gap-1",
        preset:
          "inline-flex h-7 items-center rounded-md px-2 text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        date_fields: "flex items-center gap-1 [&>input]:h-7 [&>input]:w-36 [&>input]:text-xs"
      },
      variants: %{
        active: %{
          true => %{preset: "bg-[var(--incant-primary)] text-[var(--incant-text-inverted)]"},
          false => %{
            preset:
              "border border-[var(--incant-border)] text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)]"
          }
        }
      },
      default_variants: %{active: false}
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
        root: "flex-1 space-y-5 overflow-y-auto px-3 py-4",
        group_label:
          "px-2 text-[10px] font-semibold uppercase tracking-wider text-[var(--incant-text-muted)]",
        group_items: "mt-1 space-y-1"
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

  def recipe(:filters) do
    %Recipe{
      slots: %{
        root: "border-b border-[var(--incant-border-muted)] px-3 py-2.5",
        toolbar: "flex min-h-9 flex-wrap items-center gap-2",
        search_form: "min-w-48 flex-1 sm:max-w-72",
        search:
          "h-10 w-full rounded-md sm:h-8 border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)]",
        chips: "flex min-w-0 flex-wrap items-center gap-1.5",
        chip:
          "inline-flex h-10 max-w-full sm:h-8 items-stretch overflow-hidden rounded-md border border-[color-mix(in_oklab,var(--incant-primary)_28%,var(--incant-border))] bg-[color-mix(in_oklab,var(--incant-primary)_8%,var(--incant-bg-elevated))] text-xs text-[var(--incant-text-toned)]",
        chip_edit:
          "inline-flex min-w-0 items-center gap-1.5 px-2 hover:bg-[var(--incant-bg-accented)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--incant-primary)]",
        chip_label: "font-semibold text-[var(--incant-text-highlighted)]",
        chip_remove:
          "inline-flex w-7 shrink-0 items-center justify-center border-l border-[var(--incant-border-muted)] text-base text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--incant-primary)]",
        trigger:
          "inline-flex h-10 items-center sm:h-8 gap-1.5 rounded-md border border-dashed border-[var(--incant-border)] px-2.5 text-xs font-medium text-[var(--incant-text-toned)] hover:border-[var(--incant-primary)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        count:
          "inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-[var(--incant-primary)] px-1 text-[10px] text-[var(--incant-text-inverted)]",
        clear_all:
          "h-10 px-1.5 sm:h-8 text-xs text-[var(--incant-text-muted)] underline-offset-4 hover:text-[var(--incant-text-highlighted)] hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--incant-primary)]",
        dialog:
          "fixed inset-x-3 bottom-3 top-auto z-50 m-0 max-h-[calc(100dvh-1.5rem)] w-auto max-w-none overflow-hidden rounded-xl border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-0 text-[var(--incant-text-toned)] shadow-2xl backdrop:bg-black/40 sm:inset-auto sm:left-1/2 sm:top-24 sm:max-h-[min(42rem,calc(100dvh-7rem))] sm:w-[32rem] sm:-translate-x-1/2",
        dialog_header:
          "flex items-start justify-between gap-4 border-b border-[var(--incant-border-muted)] px-4 py-3",
        dialog_title: "text-base font-semibold text-[var(--incant-text-highlighted)]",
        dialog_description: "mt-0.5 text-xs text-[var(--incant-text-muted)]",
        dialog_close:
          "inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-md text-xl text-[var(--incant-text-muted)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--incant-primary)]",
        dialog_body: "max-h-[calc(100dvh-11rem)] space-y-1 overflow-y-auto p-2 sm:max-h-[31rem]",
        dialog_footer:
          "flex min-h-14 items-center justify-end gap-2 border-t border-[var(--incant-border-muted)] px-4 py-2.5",
        empty: "px-3 py-8 text-center text-sm text-[var(--incant-text-muted)]",
        definition:
          "group rounded-lg border border-transparent open:border-[var(--incant-border-muted)] open:bg-[var(--incant-bg-muted)]",
        definition_summary:
          "flex min-h-11 cursor-pointer list-none items-center justify-between gap-3 rounded-lg px-3 py-2 text-sm font-medium text-[var(--incant-text-highlighted)] hover:bg-[var(--incant-bg-accented)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-[var(--incant-primary)] [&::-webkit-details-marker]:hidden",
        definition_meta: "text-xs font-normal text-[var(--incant-text-muted)]",
        definition_editor: "border-t border-[var(--incant-border-muted)] px-3 py-3",
        editor_form: "flex flex-col items-stretch gap-2 sm:flex-row sm:items-end",
        editor_field:
          "flex min-w-0 flex-1 flex-col gap-1 text-xs font-medium text-[var(--incant-text-muted)]",
        date_editor: "min-w-0 flex-1 space-y-2",
        date_presets: "flex flex-wrap items-center gap-1",
        date_preset:
          "inline-flex h-7 items-center rounded-md border border-[var(--incant-border)] px-2 text-xs text-[var(--incant-text-toned)] hover:border-[var(--incant-primary)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--incant-primary)]",
        date_fields: "grid min-w-0 flex-1 grid-cols-2 gap-2",
        clear_filter:
          "mt-2 text-xs text-[var(--incant-text-muted)] underline-offset-4 hover:text-[var(--incant-danger)] hover:underline"
      }
    }
  end

  def recipe(:table) do
    %Recipe{
      slots: %{
        filter_bar: "border-b border-[var(--incant-border-muted)] px-3 py-2",
        filter_form:
          "flex flex-wrap items-end gap-2 [&>label]:min-w-28 [&>label]:text-[10px] [&>label>input]:h-7 [&>label>select]:h-7",
        toolbar:
          "flex flex-wrap items-center justify-between gap-2 border-b border-[var(--incant-border-muted)] px-3 py-2",
        toolbar_group: "flex flex-wrap items-center gap-1.5",
        toolbar_hint: "text-xs text-[var(--incant-text-muted)]",
        checkbox_cell: "w-8 px-3 py-1.5",
        checkbox:
          "h-3.5 w-3.5 rounded border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] text-[var(--incant-primary)] focus:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        viewport: "overflow-x-auto",
        root: "w-full min-w-full text-sm",
        head:
          "border-b border-[var(--incant-border)] bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]",
        header_cell: "h-8 px-3 font-medium",
        sort_button:
          "inline-flex items-center gap-1 rounded px-1 py-0.5 hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[color-mix(in_oklab,var(--incant-primary)_18%,transparent)]",
        body: "divide-y divide-[var(--incant-border-muted)]",
        row: "h-9 hover:bg-[var(--incant-bg-muted)]",
        cell: "px-3 py-1.5 text-[var(--incant-text-toned)]",
        cell_content: "block",
        boolean: "inline-flex items-center gap-1.5 text-xs",
        empty: "px-3 py-8 text-center text-sm text-[var(--incant-text-muted)]",
        empty_action:
          "mt-2 inline-flex h-8 items-center rounded-md border border-[var(--incant-border)] px-3 text-xs font-medium text-[var(--incant-text-toned)] hover:bg-[var(--incant-bg-accented)] hover:text-[var(--incant-text-highlighted)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--incant-primary)]",
        empty_hint: "mt-1 text-xs text-[var(--incant-text-dimmed)]",
        actions: "w-px px-2 py-1.5 text-right sm:px-3",
        action_group:
          "inline-flex flex-col items-stretch gap-0.5 sm:flex-row sm:items-center sm:gap-1",
        link: "font-medium text-[var(--incant-text-highlighted)] hover:underline",
        pagination:
          "flex min-h-10 flex-wrap items-center justify-between gap-2 border-t border-[var(--incant-border)] px-3 py-1.5 text-xs text-[var(--incant-text-muted)]",
        pagination_actions: "ml-auto flex flex-wrap items-center justify-end gap-1",
        page_size: "mr-1 inline-flex items-center gap-1.5",
        page_size_select:
          "h-7 rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-1.5 text-xs text-[var(--incant-text-toned)] outline-none focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_15%,transparent)]"
      },
      variants: %{
        align: %{
          right: %{
            header_cell: "text-right",
            sort_button: "ml-auto",
            cell: "text-right tabular-nums"
          },
          left: %{}
        },
        truncate: %{
          true => %{cell: "max-w-[28rem]", cell_content: "truncate"},
          false => %{}
        },
        density: %{
          compact: %{row: "h-8"},
          default: %{row: "h-10"},
          comfortable: %{row: "h-12"}
        },
        identifier: %{
          true => %{cell_content: "font-mono text-xs"},
          false => %{}
        },
        value: %{
          true => %{boolean: "text-[var(--incant-success)]"},
          false => %{boolean: "text-[var(--incant-text-muted)]"}
        },
        clickable: %{
          true => %{row: "cursor-pointer"},
          false => %{}
        }
      },
      default_variants: %{
        align: :left,
        truncate: false,
        density: :default,
        identifier: false,
        value: false,
        clickable: false
      }
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
        root:
          "grid grid-cols-2 gap-3 xl:grid-cols-[repeat(var(--incant-grid-columns),minmax(0,1fr))]"
      }
    }
  end

  def recipe(:widget) do
    %Recipe{
      slots: %{
        root:
          "col-span-2 min-w-0 rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-3",
        framed:
          "col-span-2 min-w-0 overflow-hidden rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)]",
        title_row: "flex items-center justify-between gap-3",
        header:
          "flex items-center justify-between gap-3 border-b border-[var(--incant-border-muted)] p-3",
        eyebrow:
          "text-[11px] font-medium uppercase tracking-wide text-[var(--incant-text-muted)]",
        title: "mt-1 font-mono text-sm font-semibold text-[var(--incant-text-highlighted)]",
        stat_label: "text-xs font-medium text-[var(--incant-text-muted)]",
        stat_value:
          "mt-2 text-2xl font-semibold tracking-tight tabular-nums text-[var(--incant-text-highlighted)] sm:text-3xl",
        stat_delta: "mt-2 text-xs font-medium",
        error: "text-base text-[var(--incant-error)]",
        message: "p-3 text-sm text-[var(--incant-text-muted)]",
        message_error: "p-3 text-sm text-[var(--incant-error)]",
        chart: "mt-3 rounded-md bg-[var(--incant-bg-muted)] p-3",
        chart_svg: "h-32 w-full",
        chart_labels:
          "mb-1 flex items-center justify-between text-[11px] text-[var(--incant-text-muted)]",
        chart_placeholder: "flex min-h-full w-full flex-col justify-end gap-3",
        chart_line: "h-16 rounded-[50%] border-t-2 border-[var(--incant-primary)] opacity-80",
        chart_axis:
          "mt-1 flex items-center justify-between text-[11px] text-[var(--incant-text-muted)]",
        bar: "fill-[var(--incant-primary)]",
        table_viewport: "overflow-x-auto",
        table_footer:
          "border-t border-[var(--incant-border-muted)] px-3 py-2 text-xs text-[var(--incant-text-muted)]"
      },
      variants: %{
        kind: %{
          stat: %{
            root:
              "col-span-1 p-3 transition-colors hover:border-[var(--incant-border-accented)] hover:shadow-sm sm:p-4"
          },
          default: %{}
        },
        positive: %{
          true => %{stat_delta: "text-[var(--incant-success)]"},
          false => %{stat_delta: "text-[var(--incant-error)]"}
        }
      },
      default_variants: %{kind: :default, positive: true}
    }
  end
end
