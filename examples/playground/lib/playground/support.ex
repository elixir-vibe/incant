defmodule Playground.Support do
  @moduledoc false

  alias Playground.Support.Ticket

  def list_tickets(_params \\ %{}) do
    [
      %Ticket{id: 1, account_id: 1, title: "Model latency spike", priority: :high, status: :open, inserted_at: "30m ago"},
      %Ticket{id: 2, account_id: 1, title: "Billing export question", priority: :normal, status: :triaged, inserted_at: "3h ago"}
    ]
  end
end
