# Getting Started

Incant generates LiveView admin surfaces from Elixir metadata. A typical Phoenix application installs the package, mounts one admin root, imports the browser behavior, and replaces the generated sample with application resources.

## Requirements

- Elixir 1.19 or later
- Phoenix LiveView 1.1 or later
- Volt 0.17 or later for the supported browser-asset path
- Ecto when using schema-backed resources

## Install

Add Incant to `mix.exs`:

```elixir
def deps do
  [
    {:incant, "~> 0.1"}
  ]
end
```

Fetch dependencies and run the Igniter-powered installer:

```bash
mix deps.get
mix incant.install
```

Preview changes first when needed:

```bash
mix incant.install --dry-run
```

The installer creates:

```text
lib/my_app/admin.ex
lib/my_app/admin/resources/sample.ex
lib/my_app/admin/themes/default.ex
```

When standard Phoenix files are present, it also:

- adds `use Incant.Router` to the router;
- mounts `incant "/admin", MyApp.Admin` in the browser scope;
- adds Incant's Tailwind source to `assets/css/app.css`.

The installer is conservative. If it cannot identify a safe insertion point, it prints the manual change instead of guessing.

## Mount the router manually

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Incant.Router

  scope "/", MyAppWeb do
    pipe_through [:browser, :require_authenticated_user]

    incant "/admin", MyApp.Admin
  end
end
```

Put Incant behind the host application's operator authentication. Incant can authorize actors and rows, but it does not generate users or replace the Phoenix authentication boundary.

## Add the Tailwind source

Add the dependency source path to the host CSS:

```css
@source "../deps/incant/lib";
```

This lets Tailwind discover utility classes emitted by Incant's LiveView adapter. Keep the path relative to the host CSS file.

## Import browser behavior

Incant ships its frontend behavior as an importable package. Volt resolves packages from `deps` when configured:

```elixir
# config/config.exs
config :volt,
  resolve_dirs: ["deps"]
```

Preserve other existing `resolve_dirs` entries when adding `deps`.

Mount Incant from the host asset entry after creating the application's `LiveSocket` hooks:

```javascript
import { mountIncant } from "incant"

mountIncant()
```

`mountIncant()` installs theme switching, responsive navigation, confirmation and reveal dialogs, clipboard behavior, date-range controls, and other adapter interactions. It does not create or connect a second LiveSocket.

The standalone Incant entry is exported separately as `incant/standalone`; embedded Phoenix applications should import the regular `incant` entry.

## Define the admin root

```elixir
defmodule MyApp.Admin do
  use Incant.Admin,
    repo: MyApp.Repo,
    theme: MyApp.Admin.Themes.Default

  resource MyApp.Admin.Resources.Product
  dashboard MyApp.Admin.Dashboards.Operations
end
```

The root registers surfaces and shared configuration. Keep application queries, metrics, policies, and side effects in focused modules rather than accumulating them in the root.

## Add a resource

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource,
    schema: MyApp.Catalog.Product,
    repo: MyApp.Repo

  table do
    column :name, link: true
    column :status, as: :badge
    column :price, format: :money
    column :updated_at, format: :relative

    filter :status, :select, options: [:draft, :active, :archived]
    search [:name]
  end
end
```

Visit `/admin`. The table loads through the configured repo with search, sorting, filters, pagination, and detail navigation.

## Choose a deployment mode

- [Library Mode](library-mode.md) mounts local modules in a host Phoenix application. This is the default and starts no Incant supervision children.
- [Standalone Mode](standalone-mode.md) runs a central Incant endpoint that discovers service-owned surfaces over [SafeRPC](https://hexdocs.pm/safe_rpc).

## Next steps

- [Project Structure](project-structure.md)
- [Resources](../features/resources.md)
- [Dashboards](../features/dashboards.md)
- [Authorization](../features/authorization.md)
- [Themes and LiveView](../features/themes-and-liveview.md)
