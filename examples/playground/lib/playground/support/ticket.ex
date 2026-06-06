defmodule Playground.Support.Ticket do
  @moduledoc false

  use Ecto.Schema

  embedded_schema do
    field(:account_id, :integer, default: 1)
    field(:title, :string)
    field(:priority, Ecto.Enum, values: [:low, :normal, :high], default: :normal)
    field(:status, Ecto.Enum, values: [:open, :triaged, :closed], default: :open)
    field(:inserted_at, :string)
  end

  def changeset(ticket, attrs) when is_map(ticket) and not is_struct(ticket) do
    changeset(struct(__MODULE__, ticket), attrs)
  end

  def changeset(ticket, attrs) do
    ticket
    |> Ecto.Changeset.cast(attrs, [:title, :priority, :status])
    |> Ecto.Changeset.validate_required([:title])
  end
end
