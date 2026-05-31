defmodule Incant.DataSourceTest do
  use ExUnit.Case, async: true

  defmodule Source do
    use Incant.DataSource

    @impl Incant.DataSource
    def capabilities, do: [:filter, :sort]

    @impl Incant.DataSource
    def query(%Incant.Query{filters: filters}) do
      {:ok, %Incant.Result{rows: [%{filters: filters}], columns: [:filters], total_count: 1}}
    end
  end

  test "defines data source behaviour defaults and query contract" do
    assert Source.schema() == []
    assert Source.capabilities() == [:filter, :sort]

    assert {:ok, result} = Source.query(%Incant.Query{filters: %{status: :published}})
    assert result.rows == [%{filters: %{status: :published}}]
    assert result.columns == [:filters]
    assert result.total_count == 1
  end
end
