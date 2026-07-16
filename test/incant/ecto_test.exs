defmodule Incant.EctoTest do
  use ExUnit.Case, async: true

  import Ecto.Query

  defmodule Product do
    use Ecto.Schema

    schema "products" do
      field(:name, :string)
      field(:inserted_at, :utc_datetime)
    end
  end

  defmodule Repo do
    def aggregate(%Ecto.Query{}, :count, :id), do: 42
  end

  test "applies allowlisted sorting with a deterministic tie-breaker" do
    query =
      Product
      |> Incant.Ecto.sort(%{sort: "-name"}, [:name], tie_breaker: :id)

    assert inspect(query) =~ "order_by: [desc: p0.name, desc: p0.id]"

    unsorted = Incant.Ecto.sort(Product, %{sort: "private_field"}, [:name])
    assert unsorted.order_bys == []
  end

  test "applies a default sort when the request has none" do
    query = Incant.Ecto.sort(Product, %{}, [:name], default: {:inserted_at, :desc})

    assert inspect(query) =~ "order_by: [desc: p0.inserted_at, desc: p0.id]"
  end

  test "counts, clamps, and paginates a query" do
    {query, page} =
      Incant.Ecto.page(from(product in Product), Repo, %{page: "8", page_size: "10"})

    assert page == %{page: 5, page_size: 10, total: 42, total_pages: 5}
    assert query.limit != nil
    assert query.offset != nil
  end
end
