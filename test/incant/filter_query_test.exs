defmodule Incant.FilterQueryTest do
  use ExUnit.Case, async: true

  alias Incant.Filters.{Boolean, MultiSelect, Select}
  alias Incant.Resource.Metadata
  alias Incant.Table.Filter

  defmodule Product do
    use Ecto.Schema

    schema "products" do
      field(:inventory, :integer)
      field(:published, :boolean)
      field(:status, Ecto.Enum, values: [:active, :draft])
    end
  end

  test "select filters bind cast Ecto values" do
    query = Select.apply_query(%Filter{name: :inventory}, Product, "42", context())

    assert where_param(query) == 42
  end

  test "boolean filters bind cast Ecto values" do
    query = Boolean.apply_query(%Filter{name: :published}, Product, "true", context())

    assert where_param(query) == true
  end

  test "multi-select filters bind cast Ecto values" do
    query =
      MultiSelect.apply_query(%Filter{name: :status}, Product, ["active", "draft"], context())

    assert where_param(query) == [:active, :draft]
  end

  defp context do
    %{resource: %Metadata{schema: Product}}
  end

  defp where_param(%Ecto.Query{wheres: [%{params: [{value, _type}]}]}), do: value
end
