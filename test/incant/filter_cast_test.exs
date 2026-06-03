defmodule Incant.FilterCastTest do
  use ExUnit.Case, async: true

  alias Incant.Filters.Shared
  alias Incant.Resource.Metadata
  alias Incant.Table.Filter

  defmodule Product do
    use Ecto.Schema

    schema "products" do
      field(:inventory, :integer)
      field(:published, :boolean)
      field(:published_on, :date)
    end
  end

  test "casts query values using schema field types" do
    context = %{resource: %Metadata{schema: Product}}

    assert Shared.cast_query_value(%Filter{name: :inventory}, "42", context) == 42
    assert Shared.cast_query_value(%Filter{name: :published}, "true", context) == true

    assert Shared.cast_query_value(%Filter{name: :published_on}, "2026-05-31", context) ==
             ~D[2026-05-31]
  end
end
