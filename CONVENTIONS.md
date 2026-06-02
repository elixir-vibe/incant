# Incant Project Conventions

Incant projects should keep the admin surface structured by concept, not as a flat pile of modules.

Recommended application layout:

```text
lib/my_app/admin.ex
lib/my_app/admin/resources/*.ex
lib/my_app/admin/dashboards/*.ex
lib/my_app/admin/widgets/*.ex
lib/my_app/admin/themes/*.ex
lib/my_app/admin/policies/*.ex
lib/my_app/admin/data_sources/*.ex
lib/my_app/admin/metrics/*.ex
lib/my_app/admin/actions/*.ex
```

## Root admin module

The root module owns the mounted surface and only wires concepts together:

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    repo: MyApp.Repo,
    theme: MyApp.Admin.Themes.Default

  resource MyApp.Admin.Resources.User
  resource MyApp.Admin.Resources.Order

  dashboard MyApp.Admin.Dashboards.Overview
end
```

Keep it boring. If it starts accumulating queries, formatting, metrics, or policy code, move that code into the matching concept directory.

## Resources

Resource modules live in `admin/resources` and should be named after what they expose, not after Incant internals:

```elixir
defmodule MyApp.Admin.Resources.Order do
  use Incant.Resource,
    schema: MyApp.Orders.Order,
    repo: MyApp.Repo
end
```

Prefer `MyApp.Admin.Resources.Order` over `MyApp.Admin.OrderResource`. The folder already says it is a resource.

## Dashboards

Dashboard modules live in `admin/dashboards`:

```elixir
defmodule MyApp.Admin.Dashboards.MarketingFunnel do
  use Incant.Dashboard
end
```

## Themes

Themes live in `admin/themes`:

```elixir
defmodule MyApp.Admin.Themes.Default do
  use Incant.Theme
end
```

## Metrics and queries

Dashboard calculations, analytical queries, and table query helpers should not be hidden inside dashboard/resource modules when they grow.

Use focused modules:

```text
lib/my_app/admin/metrics/llm.ex
lib/my_app/admin/queries/orders.ex
lib/my_app/admin/data_sources/yandex_direct.ex
```

This keeps Incant code discoverable when the admin becomes a serious operational cockpit instead of a toy CRUD screen.
