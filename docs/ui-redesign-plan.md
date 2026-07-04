# Incant Admin UI Redesign Plan

Goal: a beautiful, modern, reusable admin UI (Linear/Vercel-dashboard quality) rendered by
the default LiveView adapter, proven against the LLMProxy admin at `http://127.0.0.1:4001/`.

## Current baseline (2026-07-04)

Already done and should not be rediscovered during the redesign:

- Registry root `/` exists and renders an `Incant.UI.Surfaces.ServiceIndex` surface with a
  service card linking to `/llm_proxy`.
- Service base paths are absolute. Resource links under `/llm_proxy` render as
  `/llm_proxy/resources/...`, not relative `llm_proxy/resources/...` links.
- Service-backed dashboard widgets execute in the owning service through the Incant
  SafeRPC `run_widget` verb. The central admin renders portable contracts; it does not
  receive executable widget callbacks. Blank dashboard stats usually mean either a
  widget query error or an Incant version/descriptor mismatch between the central admin
  and the service app.
- LLMProxy has regression coverage for remote Operations dashboard widgets through an
  `Incant.Service.Session`; do not remove it when changing dashboard rendering.
- JSONCodec `0.2.2` fixes generated type warnings for guarded `cast:` callbacks; noisy
  OAuth JSONCodec warnings in LLMProxy should not return after dependency refreshes.

## Ground rules (do not violate)

- All styling changes go through `lib/incant/ui/adapters/live_view/theme.ex` recipes and
  the CSS tokens in `assets/css/app.css`. Do not scatter class strings in templates
  (exception: one-off layout in `adapter.ex` may keep utility classes, but prefer recipes).
- Keep the semantic UI layer thin per `AGENTS.md`: no `Incant.UI.Button` /
  `Incant.UI.Dialog` style generic components in core. New visual concepts live in the
  adapter (`Incant.UI.Adapters.LiveView.*`) or as recipes.
- No `tabindex` in core structs; adapters own ARIA/keyboard behavior.
- After every phase: rebuild assets if needed, screenshot the four key pages and compare:
  `/`, `/llm_proxy/dashboards/operations`, `/llm_proxy/resources/api_key`,
  `/llm_proxy/resources/message`.
  Use agent-browser through `npx` (do not assume a global install):
  `npx -y agent-browser open <url> --args "--no-sandbox"` then
  `npx -y agent-browser screenshot /tmp/check.png` and inspect.
- Run `mix format` and `mix test` after each phase.

---

## Phase 1 — Correctness bugs (small, high impact)

The remote-widget/root-link correctness bugs are already fixed. Phase 1 now focuses on
rendering correctness that is visible in the LLMProxy admin pages.

1. **Column labels.** `lib/incant/ui/adapters/live_view/table.ex` renders `{column.id}`
   in the header sort button. Render `{column.label}` instead. Verify: API Keys page
   shows "Spend", "Input tokens", not `total_spend_usd`.
2. **Value formatting.** Extend `lib/incant/live/format.ex`:
   - `:number` → thousands separators (`2,752,554`). Implement a private
     `delimit_integer/1`; handle integers and floats.
   - `:datetime` → `2026-07-01 15:55` (UTC, minute precision) for `DateTime`,
     `NaiveDateTime`, and ISO8601 strings; fall back to `to_string`.
   - `:date`, `:time` → ISO without sub-second noise.
   - `:boolean` → render handled in adapter (see Phase 3 badge), but Format should map
     `true/false` to `"Yes"/"No"` as display fallback.
   - `:relative` → "3m ago", "2h ago", "5d ago" relative to `DateTime.utc_now/0`.
   - Keep `value/2` total (never raise). Add unit tests in `test/` mirroring existing
     format tests if present; otherwise create `test/incant/live/format_test.exs`.
3. **Long text cells.** In the table cell recipe/rendering, clamp cell content:
   add a `truncate` variant to the `:table` recipe `cell` slot using
   `max-w-[28rem] truncate` (single line, ellipsis) applied when the cell value is a
   string longer than ~120 chars OR when the column has `sensitive: true` or
   `format: :text`. Full value stays available on the row detail. Add `title` attribute
   with a 200-char prefix for hover. Verify: Messages table rows are one line tall.
4. **Dashboard table widget column order.** `lib/incant/ui/adapters/live_view/helpers.ex`
   `table_columns/1` uses `Map.keys` (unordered). If rows are keyword-ordered maps you
   cannot recover order; instead accept an optional `columns:` on the widget value
   (`%{columns: [...], rows: [...]}`) and fall back to sorted `Map.keys`. Update
   `dashboard.ex` table widget to use it. Keep this compatible with remote `run_widget`
   results; service widgets may return either bare row lists or the new envelope shape.
5. **Remove debug badges.** Delete the `span {@widget.span}` badges from timeseries and
   table widgets in `lib/incant/ui/adapters/live_view/dashboard.ex`. Span is layout
   metadata, never UI copy.
6. **Empty-state copy.** Replace developer jargon empty state ("Add a resource index
   callback...") with user copy: title "No results", body "Try adjusting or clearing the
   filters." Keep the developer hint only when `env`/config marks debug mode (add a
   `debug: boolean` to `Incant.UI.Env` defaulting false; set from
   `config :incant, debug: true` via `Incant.UI.Config`).
7. **Confirm text.** `data-confirm={action.opts[:confirm] && "Are you sure?"}` — when
   `confirm` is a binary use it as the message; `true` keeps the default. Apply in
   `table.ex` (row actions, bulk actions, page actions).
8. **Sensitive columns.** Verify `sensitive: true` columns are redacted in LiveView
   rendering, not just RPC. Check `lib/incant/sensitive.ex` call sites in
   `lib/incant/ui/regions/table.ex` / `lib/incant/live/rows.ex`. If LiveView shows
   cleartext, route cell display through `Incant.Sensitive.redact_value/2` unless the
   actor has an explicit `reveal` permission (policy check via
   `Incant.Live.Authorization`). Render redacted values as a muted `•••• redacted` badge
   with a per-cell "reveal" ghost button (click-to-reveal event `incant:event`
   op=`reveal_cell`) only when policy allows.

## Phase 2 — Shell & navigation (the "modern admin" frame)

1. **Topbar.** In `adapter.ex`:
   - Left: breadcrumbs — `Service / Section / Page` derived from `env` + surface
     (e.g. `llm_proxy / Resources / API Keys`). Muted, `/`-separated, last segment
     highlighted. Keep it in the adapter; no new core structs needed (data already in
     `nav` + surface title).
   - Right: dark-mode toggle button + the existing counts (move counts into a tooltip or
     drop them entirely — drop is fine).
2. **Dark mode toggle.** Tokens already exist under `.dark` in `assets/css/app.css`.
   Add a small JS hook in `assets/js/app.js`: toggle `document.documentElement.classList`
   `dark`, persist in `localStorage("incant-theme")`, read on boot before paint (inline
   script in `lib/incant/web/layouts/root.html.heex` head to avoid flash). Toggle button
   in topbar with sun/moon inline SVG. Verify by screenshotting both modes.
3. **Sidebar polish.**
   - Brand block: keep the tracking-wide INCANT mark but make the admin title
     `text-base font-semibold`; add a subtle bottom border only.
   - Nav items: add a 3px active accent using `border-l` or a rounded active pill with
     `bg` + `text-[var(--incant-primary)]` icon-less is fine; increase item height to
     `py-2`, gap `space-y-1`.
   - Hide empty groups (e.g. "Datasets" with zero items currently renders a dead label).
     In `nav_group/1`, render nothing when `items == []`.
   - Sticky footer area of sidebar: show adapter/version string small and muted
     (optional, reusable branding hook: read `config :incant, :footer_label`).
4. **Mobile nav.** Sidebar is `hidden lg:block` with no fallback. Add a hamburger button
   in the topbar (visible `lg:hidden`) that toggles the sidebar as an overlay
   (`fixed inset-y-0 left-0 z-40` + backdrop). Pure Alpine-free: a tiny LiveView-friendly
   JS hook or `phx-click={JS.toggle(...)}` with `Phoenix.LiveView.JS`. Verify with
   `npx -y agent-browser set viewport 390 844` + screenshot.
5. **Flash/toasts.** The adapter renders no flash. Add a toast region in `render/2`
   (top-right, fixed) rendering `env.flash` (plumb Phoenix flash into `Incant.UI.Env` if
   not present — check `lib/incant/ui/env.ex` and `lib/incant/live/admin.ex`). Success =
   emerald accent, error = rose. Auto-dismiss with `phx-click` to close +
   `JS.transition`. Action results (`Incant.ActionResult`) should put_flash on success
   ("Deleted API key") and error.

## Phase 3 — Tables (the heart of an admin)

All in `theme.ex` `:table` recipe + `table.ex`:

1. **Toolbar-first filters.** Move filters out of the right sidebar into a table toolbar
   row: search input (if `filter_bar.search`) left-aligned, filter controls inline as
   compact popover-style selects/inputs, "Rows" select and column count right-aligned.
   Implementation: render `filter_bar` inside the table panel header instead of the
   `aside`; keep the `aside` layout only when there are > 4 filters (fallback).
   Update `:surface` recipe `index` slot to single-column when no aside.
   The Messages/Traces pages must show table full-width with a slim filter row on top.
2. **Header treatment.** Only render sort buttons for sortable columns
   (`column.sortable`); non-sortable headers are plain text. Sort indicator: chevron SVG
   (up/down), `aria-sort` on the `<th>`.
3. **Real checkboxes.** Replace the button-checkbox with `<input type="checkbox">`
   styled via the existing `checkbox` slot; add a select-all checkbox in the header that
   emits `incant:event` op=`row_select_all`. (Check `lib/incant/live/actions.ex` for the
   ops handled; add `row_select_all` handling in the LiveView event handler where
   `row_select` is handled.)
4. **Cell types.**
   - `:boolean` → tiny dot + Yes/No, or check/x icon, muted colors (emerald/zinc).
   - `:badge` → keep, but map an optional `color:` opt (`:success/:warning/:error/...`)
     to token colors via a badge tone variant.
   - `:money` → right-aligned tabular-nums (already partially there via `align`).
   - Auto right-align `:number`/`:money` columns when `align` unset.
   - ID-ish values (uuid) → `font-mono text-xs`, truncated to 8 chars with full value on
     hover `title`. Add a `format: :id` handled in Format + cell class.
5. **Row density & hover.** Row `h-9` is fine; add `transition-colors`, make the whole
   row clickable when a detail exists (row-level `phx-click` navigating to detail,
   `cursor-pointer`), not just the first-column link.
6. **Pagination.** Show `1–25 of 797` style range instead of "Page 1 of 32 · 797 rows";
   keep Previous/Next; add page-size select here (moved from filter sidebar) if Phase 3.1
   removed the sidebar.
7. **Loading states.** Add `phx-disable-with` to action buttons; add an
   `aria-busy`/opacity treatment on the table wrapper during patch navigation
   (LiveView `phx-page-loading` CSS class hook in app.css:
   `.phx-change-loading`, `.phx-click-loading` opacity rules).

## Phase 4 — Dashboard (make Operations look commercial)

1. **Stat cards.** In `dashboard.ex` + `:widget` recipe:
   - Structure: label (xs, muted) → value (`text-3xl font-semibold tracking-tight`,
     tabular-nums) → optional delta line (`+12.4% vs previous`, emerald/rose arrow) when
     widget value is `%{value: v, delta: d}`; plain numbers keep current behavior.
   - Equal heights, `p-4`, hover elevation subtle (`hover:border-accented`).
2. **Uniform grid.** LLMProxy declares spans 2/2/2/3/3 → uneven. Change the LLMProxy
   dashboard (in `llm_proxy` repo, `lib/llm_proxy/admin/dashboards/operations.ex`) to
   five equal stats: spans 12/5 ≈ use `span: 2` with a 10-col row or simply
   `span: 2`+`span: 2`+`span: 2`+`span: 3`+`span: 3` → change all to `span: 2` and add a
   sixth stat (e.g. Cache read tokens) OR keep 5 and let the grid be
   `xl:grid-cols-10` when all spans sum to 10. Simplest robust fix in the adapter:
   compute `grid-cols` from the dashboard `grid columns:` DSL value (already 12) and
   keep spans — then fix LLMProxy spans to 2/2/2/3/3 → 2/2/2/2/2 + widen tables.
3. **Real timeseries chart.** Replace the fake `chart_line` ellipse with an inline SVG
   sparkline/area renderer (pure HEEx, no JS lib): polyline from points, gradient fill
   via `<linearGradient>` with `var(--incant-primary)`, min/max Y labels, first/last X
   labels. Keep bars variant for `:timeseries` but render as SVG rects with rounded
   tops and hover `<title>` tooltips. This must stay dependency-free.
4. **Dashboard tables.** Reuse the Phase 3 table styles (they currently use raw
   `Theme.slot(:table, ...)` — good) but ensure: header labels humanized, number
   columns right-aligned, empty state "No data yet" centered, and the panel gets the
   same framed header as resource tables.
5. **Date-range variable control.** Replace the two bare From/To text inputs for
   `:date_range` dashboard variables with preset chips: `1h · 24h · 7d · 30d · Custom`
   (chip = `:button` recipe, active = primary). "Custom" reveals two `type="date"`
   inputs. The DSL already has `default: "24h"`. Wire chips to the existing
   `dashboard_variable_commit` event with `var[range]=24h` values. Keep the generic
   From/To rendering as a fallback for `Incant.UI.Controls.DateRange` in resource
   filters, but use `type="date"` inputs there too.
6. **Variables bar placement.** Dashboard "Filters" panel is oversized. Render dashboard
   variables as a slim inline row directly under the page header (no panel chrome, no
   "Filters" heading) — chips + controls, right-aligned refresh timestamp optional.

## Phase 5 — Forms, detail, empty states

1. **Detail (inspector).** Verify `row_detail` navigation works end to end on Messages
   (click timestamp → detail surface). Debug via `lib/incant/live/admin.ex` routing if
   it doesn't. Style: definition list is fine; add `font-mono` for id/timestamps, render
   long text fields (`user_message`) full-width (`md:col-span-2 xl:col-span-3`) in a
   `whitespace-pre-wrap` block with copy-to-clipboard ghost button (JS hook
   `navigator.clipboard`).
2. **Forms.** Add proper focus ring consistency (already good), field descriptions
   (support `help:` opt on form fields → muted text under input), destructive style for
   delete-like submit actions, and `phx-disable-with="Saving..."` on Save.
3. **Boolean form control** should be a styled switch (label + `<input type=checkbox>`
   with peer-checked track styling), replacing any text input fallback for booleans.
   Check `lib/incant/ui/adapters/live_view/form.ex` fallback clause.
4. **Empty states.** Design one reusable empty-state block in the `:panel` recipe: icon
   (inline SVG, muted), title, body, optional primary action ("New record" when form
   enabled). Apply to: empty table, empty service index, access denied.
5. **Service index cards** (`/`). The functional root service index already exists.
   Polish it here: add hover lift (`hover:shadow-sm`), align the version badge, use a
   tabular stats row with dividers, and add a subtle chevron/arrow affordance.

## Phase 6 — Reusability & theming hardening

1. **Deduplicate `Incant.Live.Components`.** `card/badge/input/select` there hardcode
   class strings that drift from `theme.ex`. Point them at `Theme.slot/3` equivalents.
2. **Theme override hook.** Confirm `Incant.Theme` (DSL) can override recipe slots; if
   not, add a merge point: adapter reads optional
   `config :incant, MyAdmin, theme_overrides: %{recipe => %{slot => classes}}` merged in
   `Theme.slot/3`. Keep tokens (`--incant-*`) as the primary theming surface and
   document: "recolor via CSS tokens, restructure via recipe overrides".
3. **Density config.** `--incant-table-row-height` token exists but is unused; wire the
   `density: :compact` resource DSL option through `Incant.UI.Regions.Table` to a
   `density` variant on the `:table` recipe (compact `h-8`, default `h-10`,
   comfortable `h-12`).
4. **Docs.** Add `docs/theming.md`: tokens table, dark mode, recipe override example,
   and a "reuse in another project" quickstart.
5. **Accessibility pass.** `aria-sort`, `aria-current="page"` on active nav, labelled
   controls (every input has a `<label>` — mostly true), focus-visible everywhere,
   `role="status"` on toasts, Escape closes mobile sidebar.

---

## Verification checklist per phase

```bash
cd examples/playground || true   # or run against llm_proxy on :4001
mix format --check-formatted && mix test
npx -y agent-browser open http://127.0.0.1:4001/llm_proxy/resources/api_key --args "--no-sandbox"
npx -y agent-browser screenshot /tmp/after.png
```

Visual acceptance for "done":
- API Keys: humanized headers, formatted numbers, filters in toolbar, full-width table.
- Messages: one-line truncated message cells, working detail view with wrapped full text.
- Operations: equal stat cards with formatted values, real SVG sparkline/bars, slim
  variable chips row, populated (or gracefully empty) tables without span badges.
- Root: polished service cards, breadcrumb topbar, dark-mode toggle works in both modes.
- Mobile (390px): hamburger opens sidebar overlay; tables scroll horizontally.
