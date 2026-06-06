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
        body: "p-4"
      },
      variants: %{
        kind: %{
          filter: %{root: "rounded-lg", body: "space-y-3 p-3"},
          form: %{root: "max-w-[880px]", body: "grid gap-4 md:grid-cols-2"},
          table: %{root: "min-w-0"},
          inspector: %{root: "max-w-[980px]"}
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
        input:
          "h-8 w-full rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] px-2.5 text-sm font-normal normal-case tracking-normal text-[var(--incant-text-highlighted)] outline-none placeholder:text-[var(--incant-text-dimmed)] transition-colors focus:border-[var(--incant-primary)] focus:ring-2 focus:ring-[color-mix(in_oklab,var(--incant-primary)_12%,transparent)]",
        error: "text-xs font-normal normal-case tracking-normal text-[var(--incant-error)]"
      },
      variants: %{
        span: %{
          full: %{root: "md:col-span-2"},
          auto: %{}
        }
      },
      default_variants: %{span: :auto}
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

  def recipe(:table) do
    %Recipe{
      slots: %{
        root: "min-w-full text-sm",
        head:
          "border-b border-[var(--incant-border)] bg-[var(--incant-bg-muted)] text-left text-[11px] uppercase tracking-wide text-[var(--incant-text-muted)]",
        header_cell: "h-8 px-3 font-medium",
        row: "h-9 hover:bg-[var(--incant-bg-muted)]",
        cell: "px-3 py-1.5 text-[var(--incant-text-toned)]",
        pagination:
          "flex h-10 items-center justify-between gap-3 border-t border-[var(--incant-border)] px-3 text-xs text-[var(--incant-text-muted)]"
      },
      variants: %{
        align: %{
          right: %{cell: "text-right tabular-nums"},
          left: %{}
        }
      },
      default_variants: %{align: :left}
    }
  end
end
