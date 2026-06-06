defmodule Playground.Admin.Resources.Product do
  @moduledoc false

  use Incant.Resource,
    schema: Playground.Catalog.Product

  alias Playground.Catalog

  data(&Catalog.list_products/1)

  form do
    field(:name)
    field(:status, :select, options: [:draft, :active, :archived])
    field(:price, :number)
    field(:inventory, :number)
  end

  table density: :compact, saved_views: true do
    column(:name, link: true)
    column(:status, as: :badge)
    column(:price, format: :money)
    column(:inventory, align: :right)
    column(:inserted_at, format: :relative)

    filter(:status, :select, options: [:draft, :active, :archived])
    filter(:inserted_at, :date_range)

    action(:archive, confirm: true, tone: :danger, callback: &Catalog.archive_product/1)

    search([:name])
  end
end
