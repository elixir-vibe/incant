defmodule Incant.Admin.ContractTest do
  use ExUnit.Case, async: true

  defmodule BadOptionResource do
    use Incant.Resource, title: "Bad"

    table do
      column(:name, label: "Name", helper: DateTime.utc_now())
    end
  end

  defmodule BadOptionAdmin do
    use Incant.Admin

    resource(BadOptionResource)
  end

  defmodule ModuleOptionResource do
    use Incant.Resource, title: "Module option"

    table do
      column(:name, label: Date)
    end
  end

  defmodule ModuleOptionAdmin do
    use Incant.Admin

    resource(ModuleOptionResource)
  end

  defmodule SensitiveResource do
    use Incant.Resource, title: "Sensitive"

    table do
      column(:name)
      column(:api_key, secret: true)
      column(:prompt, sensitive: true)
    end

    form do
      field(:api_key, :password, redacted: true)
    end
  end

  defmodule SensitiveAdmin do
    use Incant.Admin

    resource(SensitiveResource)
  end

  test "contract descriptions omit unknown local options" do
    contract = Incant.Admin.describe(BadOptionAdmin)
    assert [%{table: %{columns: [%{opts: %{label: "Name"}}]}}] = contract.resources
  end

  test "contract descriptions reject module atoms in public option values" do
    assert_raise ArgumentError, ~r/module atoms are not portable/, fn ->
      Incant.Admin.describe(ModuleOptionAdmin)
    end
  end

  test "contract descriptions include portable sensitive field hints" do
    contract = Incant.Admin.describe(SensitiveAdmin)

    assert [resource] = contract.resources
    assert %{opts: %{secret: true}} = Enum.find(resource.table.columns, &(&1.id == "api_key"))
    assert %{opts: %{sensitive: true}} = Enum.find(resource.table.columns, &(&1.id == "prompt"))
    assert [%{opts: %{redacted: true}}] = resource.form.fields
  end
end
