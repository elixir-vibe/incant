defmodule Playground.Admin.FormRepo do
  @moduledoc false

  def insert(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      ticket = Ecto.Changeset.apply_changes(changeset)
      {:ok, %{ticket | id: ticket.id || 99, inserted_at: ticket.inserted_at || "now"}}
    else
      {:error, changeset}
    end
  end

  def update(%Ecto.Changeset{} = changeset) do
    if changeset.valid? do
      {:ok, Ecto.Changeset.apply_changes(changeset)}
    else
      {:error, changeset}
    end
  end
end
