# Installation

Incant ships an Igniter-powered installer:

```sh
mix incant.install
```

The task creates:

```text
lib/my_app/admin.ex
lib/my_app/admin/resources/sample.ex
lib/my_app/admin/themes/default.ex
```

It also patches the Phoenix router and app CSS when it can detect them.

## Router patch

The installer looks for a Phoenix router and adds `use Incant.Router` plus an admin mount in the browser scope:

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use Incant.Router

  scope "/", MyAppWeb do
    pipe_through :browser

    incant_admin "/admin", MyApp.Admin
  end
end
```

Router patching uses AST checks and AST insertion with a conservative fallback. If the router cannot be patched confidently, apply the snippet manually.

## CSS patch

The installer looks for `assets/css/app.css` and adds the Incant Tailwind source:

```css
@source "../deps/incant/lib";
```

If your app keeps CSS elsewhere, add the source manually.

## Dry run

Igniter supports previewing changes before writing them. Use the regular Igniter task options available in your environment to inspect the generated diff before applying.

## Next steps

After installation:

1. Visit `/admin`.
2. Replace the sample resource with your app resources.
3. Configure a theme or copy the default CSS variables from `Incant.Design.css_variables/0`.
4. Add a policy if the admin surface should be restricted.

See also:

- [Resources](resources.md)
- [Design and theming](design.md)
- [Authorization](authorization.md)
