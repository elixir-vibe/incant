defmodule Incant.Live.FormStateTest do
  use ExUnit.Case, async: true

  alias Incant.Live.FormState
  alias Incant.Resource.Metadata

  defmodule Repo do
    def insert({:changeset, record, attrs}), do: {:ok, Map.merge(record, attrs)}
    def update({:changeset, record, attrs}), do: {:ok, Map.merge(record, attrs)}
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
