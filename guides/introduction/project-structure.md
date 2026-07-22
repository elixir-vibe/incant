# Project Structure

Keep Incant modules grouped by admin concept so resources, policies, queries, and presentation remain easy to find as the surface grows.

A typical application layout:

```text
lib/my_app/admin.ex
lib/my_app/admin/resources/*.ex
lib/my_app/admin/dashboards/*.ex
lib/my_app/admin/datasets/*.ex
lib/my_app/admin/themes/*.ex
lib/my_app/admin/policies/*.ex
lib/my_app/admin/queries/*.ex
lib/my_app/admin/metrics/*.ex
lib/my_app/admin/actions/*.ex
```

This is a convention, not a runtime requirement. Incant accepts any module names registered on the admin root.

## Admin root

The root owns shared options and surface registration:

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    repo: MyApp.Repo,
    theme: MyApp.Admin.Themes.Default,
    policy: MyApp.Admin.Policy

  resource MyApp.Admin.Resources.User
  resource MyApp.Admin.Resources.Order
  dashboard MyApp.Admin.Dashboards.Operations
  dataset MyApp.Admin.Datasets.Sales
end
```

Keep queries, metrics, and side effects in application modules. The root should remain a readable inventory of the admin.

## Module names

The namespace already describes the role, so avoid redundant suffixes.

Prefer:

```text
MyApp.Admin.Resources.Order
MyApp.Admin.Dashboards.Marketing
MyApp.Admin.Datasets.Revenue
MyApp.Admin.Themes.Default
MyApp.Admin.Metrics.LLM
```

Avoid:

```text
MyApp.Admin.Resources.OrderResource
MyApp.Admin.Dashboards.MarketingDashboard
MyApp.Admin.Themes.DefaultTheme
```

## Resources

Name resources after the thing an operator manages:

```elixir
defmodule MyApp.Admin.Resources.Order do
  use Incant.Resource,
    schema: MyApp.Orders.Order,
    repo: MyApp.Repo
end
```

When `expose MyApp.Orders.Order` is used on the root, Incant automatically looks for the conventional override `MyApp.Admin.Resources.Order` before inferring a resource.

## Dashboards and datasets

Dashboards describe layout and presentation. Put reusable calculations in metrics or query modules:

```text
lib/my_app/admin/dashboards/operations.ex
lib/my_app/admin/metrics/operations.ex
lib/my_app/admin/queries/recent_failures.ex
```

Datasets describe analytical dimensions, metrics, and table views. Data-source adapters belong near the analytics or integration code they wrap, not inside rendering modules.

## Policies

Use one root policy for shared behavior and focused policies when a surface has different ownership:

```text
lib/my_app/admin/policy.ex
lib/my_app/admin/policies/billing.ex
lib/my_app/admin/policies/support.ex
```

Resource and dashboard policy options override the root policy for that surface.

## Actions

Short handlers can remain close to a resource. Move multi-step side effects, external calls, and reusable workflows into application action modules:

```text
lib/my_app/admin/actions/rotate_key.ex
lib/my_app/admin/actions/refund_order.ex
```

Incant should describe how an action is presented and invoked; domain modules should implement the business operation.
