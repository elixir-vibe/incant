# Incant Agent Notes

## UI architecture

Incant UI work should preserve a thin semantic UI layer instead of introducing a generic component framework.

- Put top-level framework concepts under `Incant.UI.*` (`Document`, `Adapter`, `Env`, `Event`, `Focus`, `Config`).
- Put value-changing input controls under `Incant.UI.Controls.*` (`Text`, `Select`, `DateRange`, `Relation`, etc.).
- Put page-level models under `Incant.UI.Surfaces.*`.
- Put admin page sections under `Incant.UI.Regions.*`.
- Put user-triggered commands under `Incant.UI.Actions.*`.
- Do not add generic reusable UI components such as `Incant.UI.Button`, `Incant.UI.Dialog`, or `Incant.UI.Calendar`.
- Core Incant defines what the user can do; adapters define how the user does it.
- Avoid actual `tabindex` in core UI structs. Use focus intent (`Incant.UI.Focus`) and let adapters handle ARIA, focus traps, roving tabindex, and keyboard behavior.
- Prefer adapter dispatch with fallback over global `capabilities()` registries.
- UI adapter and density should be runtime config (`config :incant, ...` or `config :incant, MyApp.Admin, ...`), not DSL unless the option is intrinsic resource semantics.
