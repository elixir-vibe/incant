defmodule Playground.Admin.Resources.Ticket do
  @moduledoc false

  use Incant.Resource,
    schema: Playground.Support.Ticket,
    repo: Playground.Admin.FormRepo

  alias Playground.Support
  alias Playground.Support.Ticket

  data(&Support.list_tickets/1)
  changeset(&Ticket.changeset/2)

  form do
    field(:title)
    field(:priority, :select, options: [:low, :normal, :high])
    field(:status, :select, options: [:open, :triaged, :closed])
  end

  table do
    column(:title, link: true)
    column(:priority, as: :badge)
    column(:status, as: :badge)
    column(:inserted_at, format: :relative)

    filter(:status, :select, options: [:open, :triaged, :closed])
    action(:edit)
  end
end
