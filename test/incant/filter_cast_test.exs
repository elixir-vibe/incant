defmodule Incant.FilterCastTest do
  use ExUnit.Case, async: true

  alias Incant.Filters.Shared
  alias Incant.Resource.Metadata
  alias Incant.Table.Filter

  defmodule Product do
    use Ecto.Schema

    schema "products" do
      field(:inventory, :integer)
      field(:price, :decimal)
      field(:published, :boolean)
      field(:published_at, :utc_datetime)
      field(:published_on, :date)
      field(:reviewed_at, :naive_datetime)
      field(:status, Ecto.Enum, values: [:active, :draft])
    end
  end

  test "casts query values using schema field types" do
    context = %{resource: %Metadata{schema: Product}}

    assert Shared.cast_query_value(%Filter{name: :inventory}, "42", context) == 42

    assert Shared.cast_query_value(%Filter{name: :price}, "12.34", context) ==
             Decimal.new("12.34")

    assert Shared.cast_query_value(%Filter{name: :published}, "true", context) == true

    assert Shared.cast_query_value(%Filter{name: :published_at}, "2026-05-31T12:34:56Z", context) ==
             ~U[2026-05-31 12:34:56Z]

    assert Shared.cast_query_value(%Filter{name: :published_on}, "2026-05-31", context) ==
             ~D[2026-05-31]

    assert Shared.cast_query_value(%Filter{name: :reviewed_at}, "2026-05-31T12:34:56", context) ==
             ~N[2026-05-31 12:34:56]

    assert Shared.cast_query_value(%Filter{name: :status}, "active", context) == :active

    assert Shared.cast_query_value(%Filter{name: :inventory}, "not an integer", context) ==
             "not an integer"
  end
end
