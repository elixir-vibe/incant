# Library Mode

Library mode renders application-owned admin modules inside the host Phoenix endpoint. It is Incant's default mode: the Incant OTP application starts no children when `serve?: false`.

The host owns:

- endpoint, sessions, and authentication;
- Ecto repos and application supervision;
- route placement and network access;
- CSS tokens and browser assets;
- admin modules, policies, queries, and side effects.

## Admin root

Register resources, dashboards, and datasets on one root:

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    repo: MyApp.Repo,
    theme: MyApp.Admin.Themes.Default,
    policy: MyApp.Admin.Policy,
    actor_assign: :current_scope,
    naming: [terms: %{openai: "OpenAI", api: "API"}]

  resource MyApp.Admin.Resources.Product
  resource MyApp.Admin.Resources.Order
  dashboard MyApp.Admin.Dashboards.Operations
  dataset MyApp.Admin.Datasets.Sales
end
```

Root options become defaults for registered surfaces. A resource or dashboard can override its repo or policy when ownership differs.

## Router and authentication

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Incant.Router

  scope "/", MyAppWeb do
    pipe_through [:browser, :require_authenticated_user, :require_operator]
    incant "/admin", MyApp.Admin
  end
end
```

Use the same session and authentication pipeline as the rest of the Phoenix application. Incant reads the configured actor assign from LiveView assigns and passes it into policy callbacks.

If `actor_assign` is omitted, Incant checks common assign names in this order:

```text
current_scope
current_user
current_admin
actor
user
```

See [Authorization](../features/authorization.md) for explicit extraction and row scoping.

## Assets

Add Incant to Tailwind scanning:

```css
@source "../deps/incant/lib";
```

Let Volt resolve the Hex dependency as a frontend package:

```elixir
config :volt,
  resolve_dirs: ["deps"]
```

Then import and mount browser behavior from the host entry:

```javascript
import { mountIncant } from "incant"

mountIncant()
```

The regular package entry contains UI behavior only. It deliberately does not connect a LiveSocket, so the host keeps its existing Phoenix socket setup.

## Schema-backed resources

An Ecto resource can infer fields and use standard query operations:

```elixir
defmodule MyApp.Admin.Resources.Order do
  use Incant.Resource,
    schema: MyApp.Sales.Order,
    repo: MyApp.Repo

  table do
    column :number, link: true
    column :status, as: :badge
    column :total, format: :money
    column :inserted_at, format: :datetime

    filter :status, :multi_select, options: [:pending, :paid, :shipped]
    filter :inserted_at, :date_range
    search [:number, :email]
  end

  form do
    field :status, :select, options: [:pending, :paid, :shipped]
    field :notes, :textarea
  end
end
```

Incant casts built-in filter values through the Ecto field type, applies policy query scoping, and passes the resulting table state through search, filters, sort, count, and pagination.

## Query-backed resources

Use application queries when a surface needs joins, aggregates, projections, or a nonstandard schema:

```elixir
defmodule MyApp.Admin.Resources.CustomerHealth do
  use Incant.Resource,
    title: "Customer Health"

  index &MyApp.Admin.Queries.customer_health/2
  read &MyApp.Admin.Queries.customer/2

  table do
    column :customer, link: true
    column :plan
    column :monthly_spend, format: :money
    column :last_seen_at, format: :relative
  end
end
```

Keep domain query logic in application modules. Resource metadata should describe presentation and available operations rather than become a second data layer.

## Forms and actions

Resource forms use declared fields or infer compatible schema fields. Create and update still run through application callbacks or Ecto changesets.

Actions can return normal success/error results, navigation, or one-time secret reveals:

```elixir
action :rotate_key,
  callback: &MyApp.Keys.rotate/2,
  confirm: "Rotate this key?",
  destructive: true
```

Use `Incant.ActionResult.Reveal` for a newly generated secret that should appear once in a protected dialog.

## UI configuration

The default adapter is `Incant.UI.Adapters.LiveView`:

```elixir
config :incant,
  ui_adapter: Incant.UI.Adapters.LiveView,
  density: :compact
```

Per-admin overrides use the admin module as the application config key:

```elixir
config :incant, MyApp.Admin,
  density: :comfortable
```

Theme tokens remain host CSS variables. See [Themes and LiveView](../features/themes-and-liveview.md).

## Testing

Admin metadata is ordinary Elixir data:

```elixir
metadata = Incant.metadata(MyApp.Admin)
assert MyApp.Admin.Resources.Order in metadata.resources
```

Use Phoenix LiveView tests for router/session rendering and focused unit tests for query callbacks, policies, action handlers, and formatters. You do not need a browser to verify the semantic contract.
