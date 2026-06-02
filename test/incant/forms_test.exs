defmodule Incant.FormsTest do
  use ExUnit.Case, async: true

  alias Incant.Form
  alias Incant.Form.Field
  alias Incant.Forms
  alias Incant.Resource.Metadata

  defmodule Product do
    defstruct [:name, :price, :published]

    def __schema__(:fields), do: [:id, :name, :price, :published, :inserted_at, :updated_at]
    def __schema__(:type, :name), do: :string
    def __schema__(:type, :price), do: :decimal
    def __schema__(:type, :published), do: :boolean
  end

  test "uses explicit form fields" do
    resource = %Metadata{form: %Form{fields: [%Field{name: :title, type: :text}]}}

    assert Forms.fields(resource) == [%Field{name: :title, type: :text}]
  end

  test "infers fields from Ecto-like schemas" do
    resource = %Metadata{schema: Product}

    assert Forms.fields(resource) == [
             %Field{name: :name, type: :string},
             %Field{name: :price, type: :number},
             %Field{name: :published, type: :boolean}
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
