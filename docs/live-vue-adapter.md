# LiveVue adapter prototype

Incant's semantic UI layer is designed so richer client adapters can live outside the core package. A LiveVue/Reka adapter should be published as a separate package, for example `incant_live_vue`.

The adapter implements `Incant.UI.Adapter` and consumes the same `Incant.UI.Document` that the default LiveView adapter renders:

```elixir
defmodule IncantLiveVue.Adapter do
  @behaviour Incant.UI.Adapter

  use Phoenix.Component

  @impl true
  def render(%Incant.UI.Document{} = document, env) do
    assigns = %{document: document, env: env}

    ~H"""
    <.vue name="IncantAdmin" v-component={%{document: @document, env: client_env(@env)}} />
    """
  end

  defp client_env(env) do
    %{
      base_path: env.base_path,
      density: env.density,
      theme: env.theme
    }
  end
end
```

Configure it per app or per admin:

```elixir
config :incant, MyApp.Admin,
  ui_adapter: IncantLiveVue.Adapter,
  density: :compact
```

## First primitives

Start with controls where client-side behavior matters most:

- date range — Reka popover/calendar with local draft state; commit through `dashboard_variable_commit` or `filter_commit`
- select/listbox — Reka select for single values; normalize empty selection to `nil`
- multiselect — Reka listbox/combobox; submit arrays using the same payload shape as LiveView forms
- action menu — Reka dropdown menu; emit `row_action` or `bulk_action`
- relation picker — combobox with remote search; emit selected id through the semantic event envelope

## Event envelope

Adapters should send one LiveView event name, `incant:event`, with a normalized semantic operation:

```js
pushEvent("incant:event", {
  op: "row_action",
  target: "archive",
  value: row.id,
  surface: "resource.MyApp.Admin.Resources.Product"
})
```

`Incant.UI.Event.parse/1` keeps non-envelope form data as `meta`, so adapters may include framework-specific details without changing the core event dispatcher.

## Boundary rules

Core Incant owns resource/dashboard semantics and authorization context. The LiveVue adapter owns rendered primitives, keyboard behavior, focus traps, ARIA, local draft state, and Reka component composition.
