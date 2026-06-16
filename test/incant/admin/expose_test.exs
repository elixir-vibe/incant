defmodule Incant.Admin.ExposeTest do
  use ExUnit.Case, async: true

  defmodule Repo do
  end

  defmodule Invoice do
    use Ecto.Schema

    schema "invoices" do
      field(:number, :string)
      field(:status, :string)
      field(:paid, :boolean)
      field(:total_cents, :integer)
      timestamps(type: :utc_datetime)
    end
  end

  defmodule Payment do
    use Ecto.Schema

    schema "payments" do
      field(:external_id, :string)
      field(:status, :string)
      field(:amount_cents, :integer)
      timestamps(type: :utc_datetime)
    end
  end

  defmodule AuditEntry do
    use Ecto.Schema

    schema "audit_entries" do
      field(:message, :string)
    end
  end

  defmodule Admin do
    use Incant.Admin, repo: Repo, service: :billing

    expose(Invoice)
    expose(Payment, readonly: true)
    expose(AuditEntry, as: :audit)
  end

  defmodule Admin.Resources.Invoice do
    use Incant.Resource, schema: Incant.Admin.ExposeTest.Invoice, title: "Custom Invoices"

    table do
      column(:number, link: true)
      column(:status, as: :badge)
      action(:capture)
    end
  end

  defmodule Admin.Resources.Audit do
    use Incant.Resource, schema: Incant.Admin.ExposeTest.AuditEntry, title: "Audit"

    table do
      column(:message)
    end
  end

  test "expose uses conventional resource module when present" do
    contract = Incant.Admin.describe(Admin)

    assert [
             %{id: "invoice", title: "Custom Invoices"} = invoice,
             %{id: "payment"} = payment,
             %{id: "audit", title: "Audit"} = audit
           ] = contract.resources

    assert Enum.map(invoice.table.columns, & &1.id) == ["number", "status"]
    assert Enum.map(invoice.table.actions, & &1.id) == ["capture"]

    assert payment.title == "Payment"

    assert Enum.map(payment.table.columns, & &1.id) == [
             "id",
             "external_id",
             "status",
             "amount_cents",
             "inserted_at",
             "updated_at"
           ]

    assert payment.table.actions == []
    assert payment.form.fields == []
    refute Map.has_key?(payment.opts, :schema)
    refute Map.has_key?(payment.opts, :repo)
    assert Enum.map(audit.table.columns, & &1.id) == ["message"]
  end
end
