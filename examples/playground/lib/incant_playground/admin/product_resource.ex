defmodule IncantPlayground.Admin.ProductResource do
  @moduledoc false

  use Incant.Resource,
    schema: IncantPlayground.Catalog.Product,
    repo: IncantPlayground.Repo

  query(&__MODULE__.index_query/2)

  table density: :compact, saved_views: true do
    column(:name, link: true)
    column(:status, as: :badge)
    column(:price, format: :money)
    column(:inventory, align: :right)
    column(:inserted_at, format: :relative)

    filter(:status, :select, options: [:draft, :active, :archived])
    filter(:inserted_at, :date_range)

    search([:name])
  end

  def index_query(query, _context), do: query
end
