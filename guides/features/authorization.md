# Authorization

Incant reuses the host application's authentication and calls application-owned policies for admin, surface, row, form, and action access. It does not generate users, sessions, roles, or login routes.

## Actor extraction

Configure the LiveView assign containing the current actor:

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    policy: MyApp.Admin.Policy,
    actor_assign: :current_scope
end
```

Without an explicit assign, Incant checks these assigns in order:

```text
current_scope
current_user
current_admin
actor
user
```

Use a callback when the actor must be derived from several assigns:

```elixir
use Incant.Admin,
  policy: MyApp.Admin.Policy,
  actor: {MyApp.Admin.Actor, :from_assigns}
```

The callback receives the LiveView assigns and returns the value passed to policies.

## Policy callbacks

Policies use a Bodyguard-compatible callback shape:

```elixir
defmodule MyApp.Admin.Policy do
  use Incant.Policy

  def authorize(:view_admin, actor, context), do: allow_admin?(actor, context)
  def authorize(:view_resource, actor, %{resource: resource}), do: can_view?(actor, resource)
  def authorize(:view_dashboard, actor, %{dashboard: dashboard}), do: can_view?(actor, dashboard)
  def authorize(:view_row, actor, %{selected_row: row}), do: can_view_row?(actor, row)
  def authorize(:create, actor, %{resource: resource, attrs: attrs}), do: can_create?(actor, resource, attrs)
  def authorize(:edit, actor, %{row: row, attrs: attrs}), do: can_edit?(actor, row, attrs)
  def authorize(:run_action, actor, %{action: action, row: row}), do: can_run?(actor, action, row)
  def authorize(:run_bulk_action, actor, %{action: action, selected_ids: ids}), do: can_run_bulk?(actor, action, ids)
  def authorize(:run_page_action, actor, %{action: action}), do: can_run_page?(actor, action)
end
```

Allow with `true` or `:ok`. Deny with `false`, `:error`, or `{:error, reason}`.

Without a configured policy, Incant allows operations. Always place the router behind host authentication even when a policy is configured.

## Query and row scoping

Authorization checks whether an operation is allowed. Scoping limits which data can be observed.

For Ecto-backed resources:

```elixir
def scope_query(actor, resource, queryable, context) do
  MyApp.Admin.Authorization.scope_query(actor, resource, queryable, context)
end
```

Incant applies query scope before search, filters, count, sorting, and pagination.

For application-owned row lists:

```elixir
def scope_rows(actor, resource, rows, context) do
  Enum.filter(rows, &can_view_row?(actor, resource, &1))
end
```

Scope hooks complement `:view_row` checks. Use both when list visibility and direct detail access need protection.

## Phoenix `current_scope`

Phoenix 1.8 applications generated with `phx.gen.auth` usually use `actor_assign: :current_scope`:

```elixir
defmodule MyApp.Admin.Policy do
  use Incant.Policy
  import Ecto.Query

  def authorize(:view_admin, %{user: user}, _context),
    do: user.role in [:admin, :operator]

  def authorize(:view_resource, _scope, _context), do: true
  def authorize(:view_dashboard, _scope, _context), do: true

  def authorize(:view_row, _scope, %{selected_row: nil}),
    do: {:error, :not_found}

  def authorize(:view_row, scope, %{selected_row: row}),
    do: row.account_id == scope.user.account_id

  def authorize(:create, %{user: user}, %{attrs: attrs}),
    do: user.role == :admin and attrs["account_id"] == to_string(user.account_id)

  def authorize(:edit, scope, %{row: row}),
    do: row.account_id == scope.user.account_id

  def authorize(:run_action, scope, %{row: row}),
    do: row.account_id == scope.user.account_id

  def authorize(:run_bulk_action, %{user: user}, _context),
    do: user.role == :admin

  def authorize(:run_page_action, %{user: user}, _context),
    do: user.role in [:admin, :operator]

  def scope_query(scope, _resource, queryable, _context) do
    where(queryable, [row], field(row, :account_id) == ^scope.user.account_id)
  end

  def scope_rows(scope, _resource, rows, _context) do
    Enum.filter(rows, &(&1.account_id == scope.user.account_id))
  end
end
```

Keep the browser route in a matching authentication pipeline:

```elixir
scope "/", MyAppWeb do
  pipe_through [:browser, :require_authenticated_user, :require_operator]
  incant "/admin", MyApp.Admin
end
```

## Surface-specific policies

Resources and dashboards can override the root policy:

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource,
    schema: MyApp.Catalog.Product,
    repo: MyApp.Repo,
    policy: MyApp.Admin.Policies.Catalog
end
```

The local policy handles checks and scoping for that surface; the root policy remains the fallback elsewhere.

## Bodyguard

Delegate from an Incant policy when the application already uses Bodyguard:

```elixir
def authorize(action, actor, context) do
  Bodyguard.permit(MyApp.Admin.Authz, action, actor, context)
end
```

Keep Incant policy modules thin and preserve domain authorization in the application's existing boundary.

## Remote services

In distributed mode, policies execute in the service that owns the admin module. The central host can pass actor/context data, but the service decides whether that data is trusted and whether the operation is allowed.

For strong boundaries, translate authenticated central identity into signed or otherwise verifiable service claims. Do not treat arbitrary HTTP `context` maps as proof of identity.
