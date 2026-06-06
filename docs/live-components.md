# LiveView adapter

Incant ships with `Incant.UI.Adapters.LiveView` as its default UI adapter. The adapter consumes semantic `Incant.UI.Document` nodes and renders Phoenix LiveView components.

The adapter is split by admin surface concern:

- Main adapter — shell and surface dispatch
- Controls — filters, variables, and basic controls
- Table — resource tables and row actions
- Form — resource forms
- Inspector — resource detail views
- Dashboard — dashboard widgets

Configure the adapter in runtime config:

```elixir
config :incant,
  ui_adapter: Incant.UI.Adapters.LiveView,
  density: :compact
```

Per-admin overrides use the admin module as the config key.
