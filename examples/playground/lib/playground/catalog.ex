defmodule Playground.Catalog do
  @moduledoc false

  alias Playground.Catalog.Product

  def list_products(_params \\ %{}) do
    [
      %Product{
        id: 1,
        account_id: 1,
        name: "Incant Pro",
        status: :active,
        price: 149.0,
        inventory: 32,
        inserted_at: "2h ago"
      },
      %Product{
        id: 2,
        account_id: 1,
        name: "Dashboard Wand",
        status: :draft,
        price: 79.0,
        inventory: 8,
        inserted_at: "1d ago"
      },
      %Product{
        id: 3,
        account_id: 2,
        name: "CMS Grimoire",
        status: :archived,
        price: 229.0,
        inventory: 0,
        inserted_at: "5d ago"
      }
    ]
  end

  def archive_product(%{row: %Product{name: name}}), do: {:ok, "Archived #{name}"}
  def archive_product(_context), do: {:error, "Product not found"}
end
