defmodule Incant.Live.FormStateTest do
  use ExUnit.Case, async: true

  alias Incant.Live.FormState
  alias Incant.Resource.Metadata

  defmodule Repo do
    def insert({:changeset, record, attrs}), do: {:ok, Map.merge(record, attrs)}
    def insert(%Ecto.Changeset{} = changeset), do: {:error, changeset}
    def update({:changeset, record, attrs}), do: {:ok, Map.merge(record, attrs)}
  end

  defmodule Product do
    use Ecto.Schema

    embedded_schema do
      field(:name, :string)
    end

    def changeset(record, attrs) do
      record
      |> Ecto.Changeset.cast(attrs, [:name])
      |> Ecto.Changeset.validate_required([:name])
    end
  end

  test "reports missing repo" do
    resource = %Metadata{changeset: fn record, attrs -> {record, attrs} end}

    assert FormState.save(:new, resource, %{}, %{}) == {:error, "Resource repo is not configured"}
  end

  test "reports missing changeset" do
    resource = %Metadata{repo: Repo}

    assert FormState.save(:new, resource, %{}, %{}) ==
             {:error, "Resource changeset is not configured"}
  end

  test "marks validation changesets with the validate action" do
    resource = %Metadata{changeset: &Product.changeset/2}

    changeset = FormState.validate(resource, %Product{}, %{})

    assert changeset.action == :validate
    assert Keyword.has_key?(changeset.errors, :name)
  end

  test "marks failed inserts with the insert action" do
    resource = %Metadata{repo: Repo, changeset: &Product.changeset/2}

    assert {:error, changeset} = FormState.save(:new, resource, %Product{}, %{})
    assert changeset.action == :insert
    assert Keyword.has_key?(changeset.errors, :name)
  end

  test "inserts new records through the repo" do
    resource = %Metadata{
      repo: Repo,
      changeset: fn record, attrs -> {:changeset, record, attrs} end
    }

    assert FormState.save(:new, resource, %{}, %{name: "Incant"}) ==
             {:ok, "Record created", %{name: "Incant"}}
  end

  test "updates existing records through the repo" do
    resource = %Metadata{
      repo: Repo,
      changeset: fn record, attrs -> {:changeset, record, attrs} end
    }

    assert FormState.save(:edit, resource, %{id: 1}, %{name: "Incant"}) ==
             {:ok, "Record updated", %{id: 1, name: "Incant"}}
  end
end
