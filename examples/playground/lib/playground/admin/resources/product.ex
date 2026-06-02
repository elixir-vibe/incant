defmodule Playground.Admin.Resources.Product do
  @moduledoc false

  alias Playground.Admin.Data

  use Incant.Resource,
    schema: Playground.Catalog.Product,
    repo: Playground.Repo

  query(&__MODULE__.index_query/2)
  data(&Data.products/1)

  table density: :compact, saved_views: true do
    column(:name, link: true)
    column(:status, as: :badge)
    column(:price, format: :money)
    column(:inventory, align: :right)
    column(:inserted_at, format: :relative)

    filter(:status, :select, options: [:draft, :active, :archived])
    filter(:inserted_at, :date_range)

    transformer :inventory_health, label: "Inventory Health" do
      query_transformer(&__MODULE__.inventory_health/3)
    end

    search([:name])
  end

  def index_query(query, _context), do: query
  def inventory_health(query, _params, _context), do: query
end
