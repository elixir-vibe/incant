defmodule Incant.TabularTest do
  use ExUnit.Case, async: true

  defmodule Row do
    defstruct [:id, :name]
  end

  test "reads list of maps" do
    rows = Incant.Tabular.to_rows([%{id: 1, name: "Sherlock"}, %{id: 2, name: "John"}])

    assert rows == [%{id: 1, name: "Sherlock"}, %{id: 2, name: "John"}]
    assert Incant.Tabular.metadata(rows) == %{columns: [:id, :name], count: 2}
  end

  test "reads structs" do
    assert Incant.Tabular.to_rows([%Row{id: 1, name: "Sherlock"}]) == [%{id: 1, name: "Sherlock"}]
  end

  test "reads map of columns" do
    data = %{id: [1, 2], name: ["Sherlock", "John"]}

    assert Incant.Tabular.to_rows(data) == [%{id: 1, name: "Sherlock"}, %{id: 2, name: "John"}]
    assert Incant.Tabular.to_columns(data, only: [:name]) == %{name: ["Sherlock", "John"]}
  end

  test "reads list of column tuples" do
    data = [{"id", [1, 2]}, {"name", ["Sherlock", "John"]}]

    assert Incant.Tabular.to_rows(data) == [
             %{"id" => 1, "name" => "Sherlock"},
             %{"id" => 2, "name" => "John"}
           ]
  end
end
