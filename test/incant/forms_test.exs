defmodule Incant.FormsTest do
  use ExUnit.Case, async: true

  alias Incant.Form
  alias Incant.Form.Field
  alias Incant.Forms
  alias Incant.Resource.Metadata

  defmodule Product do
    use Ecto.Schema

    embedded_schema do
      field(:name, :string)
      field(:price, :decimal)
      field(:published, :boolean)
      field(:published_at, :utc_datetime)
      field(:published_on, :date)
      field(:reviewed_at, :naive_datetime)
      field(:status, Ecto.Enum, values: [:active, :draft])
    end
  end

  test "uses explicit form fields" do
    resource = %Metadata{form: %Form{fields: [%Field{name: :title, type: :text}]}}

    assert Forms.fields(resource) == [%Field{name: :title, type: :text}]
  end

  test "infers fields from Ecto-like schemas" do
    resource = %Metadata{schema: Product}

    assert Forms.fields(resource) == [
             %Field{name: :name, type: :string, opts: []},
             %Field{name: :price, type: :number, opts: []},
             %Field{name: :published, type: :boolean, opts: []},
             %Field{name: :published_at, type: :datetime, opts: []},
             %Field{name: :published_on, type: :date, opts: []},
             %Field{name: :reviewed_at, type: :datetime, opts: []},
             %Field{name: :status, type: :select, opts: [options: [:active, :draft]]}
           ]
  end

  test "builds new records from schema structs" do
    resource = %Metadata{schema: Product}

    assert Forms.new_record(resource) == %Product{}
  end

  test "builds changesets from configured callbacks" do
    changeset = fn record, attrs -> {:changeset, record, attrs} end
    resource = %Metadata{changeset: changeset}

    assert Forms.changeset(resource, :record, %{name: "Incant"}) ==
             {:changeset, :record, %{name: "Incant"}}
  end
end
