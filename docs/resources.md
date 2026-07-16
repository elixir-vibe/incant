# Resources

Incant is experimental; resource DSL and renderer details may still change before a first stable release.


```elixir
defmodule MyApp.Admin.Resources.Order do
  use Incant.Resource,
    schema: MyApp.Orders.Order,
    repo: MyApp.Repo

  query &MyApp.Admin.Queries.orders_index/2
  index &MyApp.Admin.Data.orders/2
  read &MyApp.Admin.Data.order/2

  table density: :compact do
    column :number, link: true
    column :customer, value: & &1.customer.email
    column :api_key, secret: true
    column :total, format: :money
    column :status, as: :badge

    filter :status, :select
    filter :inserted_at, :date_range

    transformer :sales_performance do
      query_transformer &MyApp.Admin.Filters.sales_performance/3
    end

    search &MyApp.Admin.Filters.order_search/3
  end
end
```

See also [Authorization](authorization.md) for policy scoping and [Design and theming](design.md) for table styling.

Use `secret: true`, `sensitive: true`, or `redacted: true` on columns and form fields that must not expose raw values through table/detail models or portable contracts:

```elixir
table do
  column :provider
  column :token, secret: true
  column :user_message, sensitive: true
end

form do
  field :token, :password, redacted: true
end
```

These flags are presentation and transport-safety hints. They do not replace authorization policies for deciding who may reach a surface or action.

## Filters

Resource filters are rendered and applied through `Incant.Filter`, a behaviour-backed registry. Built-ins include `:text`, `:select`, `:multi_select`, `:date_range`, and `:boolean`. For Ecto schema-backed resources, built-in query filters cast submitted values through `Ecto.Type.cast/2`, so field types such as integers, decimals, dates, datetimes, booleans, and `Ecto.Enum` values bind as typed query params.

```elixir
filter :status, :select, options: [:draft, :published]
filter :inserted_at, :date_range
```

Override an individual filter with a module that implements `Incant.Filter`:

```elixir
filter :expensive, :boolean, filter: MyApp.Admin.Filters.ExpensiveProduct
```

```elixir
defmodule MyApp.Admin.Filters.ExpensiveProduct do
  @behaviour Incant.Filter

  use Phoenix.Component
  import Incant.Live.Components

  def control(filter, value, _assigns) do
    assigns = %{filter: filter, value: value}

    ~H"""
    <.select
      name={"table[filters][#{@filter.name}]"}
      value={@value}
      prompt="Price"
      options={[{"Expensive", "true"}, {"Cheap", "false"}]}
    />
    """
  end

  def match?(_filter, _row, value) when value in [nil, ""], do: true
  def match?(_filter, row, "true"), do: row.price_cents >= 10_000
  def match?(_filter, row, "false"), do: row.price_cents < 10_000

  def apply_query(_filter, queryable, _value, _context), do: queryable
end
```

`match?/3` is used for in-memory rows. `apply_query/4` is reserved for query-backed resources and custom data sources. To apply all submitted filter values to a queryable, use:

```elixir
Incant.Filter.apply_filters(resource.table.filters, queryable, params["filter"], context)
```

## Resource forms

Incant form metadata is changeset-first for Ecto resources. The form DSL describes admin presentation and ordering; schemas and changesets remain the source of truth for data and validation.

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource, schema: MyApp.Catalog.Product, repo: MyApp.Repo

  changeset &MyApp.Catalog.Product.changeset/2

  form do
    field :name
    field :status, :select, options: [:draft, :active, :archived]
    field :price, :number
  end
end
```

When no form fields are declared, `Incant.Forms.fields/1` can infer fields from Ecto-style `schema.__schema__/1`, excluding `:id`, `:inserted_at`, and `:updated_at`.

## Actions and row details

Resource tables can declare row, bulk, and page actions. Actions are semantic commands; adapters decide whether they render as inline buttons, menus, command palettes, drawers, or full pages.

```elixir
table do
  column :name, link: true

  action :archive,
    label: "Archive",
    tone: :danger,
    confirm: true,
    callback: &MyApp.Admin.Actions.archive_product/2

  row_detail :activity, label: "Activity"

  actions do
    bulk :export_selected,
      label: "Export selected",
      result: :download,
      callback: &MyApp.Admin.Exports.products/2

    page :sync_catalog,
      label: "Sync catalog",
      async: true,
      result: :job,
      callback: &MyApp.Admin.Actions.sync_catalog/1
  end
end
```

`action/2` and `row/2` both declare row actions. `bulk/2` declares actions that operate on selected rows. `page/2` declares resource-level actions. Row actions may declare when they apply without conflating applicability with authorization:

```elixir
action :disable,
  available_if: [enabled: true],
  confirm: "Disable this provider token?",
  callback: :disable

action :enable,
  available_if: :can_enable?,
  callback: :enable
```

Incant evaluates `available_if` while building each service row and again before execution. Declarative keyword/map conditions compare row fields exactly; callbacks receive the row and action context. Atom callbacks resolve against the owning resource module; functions and `{Module, :function}` remain available for explicit cross-module calls.

Callbacks receive action-specific context such as `%{action:, id:, row:, selected_ids:, resource:}` and the LiveView assigns. They can return semantic action results:

```elixir
Incant.ActionResult.toast("Archived")
Incant.ActionResult.refresh([:table, :widgets])
Incant.ActionResult.navigate("/admin/resources/orders")
Incant.ActionResult.download(export_id, label: "CSV export")
Incant.ActionResult.job(job_id, label: "Sync started")
Incant.ActionResult.open_surface(surface)
Incant.ActionResult.error("Cannot archive this row")
```

Shorthand returns are normalized for convenience: `:ok`, a message string, `{:ok, message}`, and `{:error, message}`.

## Application-side query resources

Use `index/2` for the resource collection and `read/2` for one record. These callbacks live in the application namespace, so Ecto queries, storage facades, authorization scoping, pagination, and transactions remain application responsibility.

A callback may return a plain list for a small collection. Incant then performs in-memory search, filtering, sorting, and pagination. Large collections should return the existing `%Incant.Result{}` with authoritative rows and count; Incant does not process or paginate those rows a second time:

```elixir
%Incant.Result{
  rows: rows,
  total_count: total,
  meta: %{page: page, page_size: page_size}
}
```

Additional bounded filter options can travel in the same result metadata without introducing a separate option model:

```elixir
%Incant.Result{
  rows: rows,
  total_count: total,
  meta: %{
    page: page,
    page_size: page_size,
    options: %{"model" => model_options}
  }
}
```

Declare the corresponding autocomplete filter with `filter :model, :combobox, options_from: :model`. The option values use the same existing `{label, value}` or `%{label:, value:}` representations as selects.

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource, schema: MyApp.Catalog.Product

  import Ecto.Query

  table do
    column :name, link: true
    filter :status, :select
  end

  def index(params, context) do
    MyApp.Catalog.Product
    |> where(account_id: ^context.actor.account_id)
    |> maybe_filter_status(params)
    |> order_by(desc: :inserted_at)
    |> MyApp.Repo.all()
  end

  def read(id, context) do
    MyApp.Repo.get_by(MyApp.Catalog.Product,
      id: id,
      account_id: context.actor.account_id
    )
  end
end
```

The DSL also accepts explicit callback declarations when the function names differ:

```elixir
index &MyApp.Admin.Products.index/2
read &MyApp.Admin.Products.read/2
# or local atom shorthand
index :search
read :lookup
```
