# Resources

Incant is experimental; resource DSL and renderer details may still change before a first stable release.


```elixir
defmodule MyApp.Admin.Resources.Order do
  use Incant.Resource,
    schema: MyApp.Orders.Order,
    repo: MyApp.Repo

  query &MyApp.Admin.Queries.orders_index/2
  data &MyApp.Admin.Data.orders/1

  table density: :compact do
    column :number, link: true
    column :customer, value: & &1.customer.email
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

## Row actions

Resource tables can declare row actions. Actions render in the table and detail view; provide a callback to execute behaviour from the LiveView.

```elixir
table do
  column :name, link: true

  action :archive,
    label: "Archive",
    tone: :danger,
    confirm: true,
    callback: &MyApp.Admin.Actions.archive_product/2
end
```

Callbacks receive `%{action:, id:, row:, resource:}` and the LiveView assigns. Return `:ok`, a message string, `{:ok, message}`, or `{:error, message}`.

## Query-backed resources

If a resource does not define `data/1`, Incant can load rows from `repo` and `schema`:

```elixir
defmodule MyApp.Admin.Resources.Product do
  use Incant.Resource, schema: MyApp.Catalog.Product, repo: MyApp.Repo

  query &__MODULE__.base_query/2

  table do
    column :name, link: true
    filter :status, :select, query: &__MODULE__.status_filter/3
  end

  def base_query(schema, _context), do: schema
  def status_filter(query, status, _context), do: query
end
```

Custom filter query callbacks run before `repo.all/1`. Built-in filters apply Ecto `where` clauses for query-backed resources and bind values cast through the schema field type.
