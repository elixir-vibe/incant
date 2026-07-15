defmodule Incant.UI.FilterStateTest do
  use ExUnit.Case, async: true

  alias Incant.UI.Controls.{Boolean, DateRange, Select, Text}
  alias Incant.UI.FilterState
  alias Incant.UI.FilterState.Condition

  test "normalizes portable values into typed applied conditions" do
    state =
      FilterState.new(nil, [
        %Text{name: "model", label: "Model", value: "codex", source: %{type: :text}},
        %Select{
          name: "kind",
          label: "Kind",
          value: "oauth",
          options: [%{label: "OAuth", value: "oauth"}],
          source: %{type: :select}
        },
        %Boolean{name: "enabled", label: "Enabled", value: "true", source: %{type: :boolean}},
        %DateRange{
          name: "created_at",
          label: "Created at",
          value: %{"from" => "2026-07-01", "to" => "2026-07-10"},
          source: %{type: :date_range}
        }
      ])

    assert [
             %Condition{name: "model", display: "codex"},
             %Condition{name: "kind", display: "OAuth"},
             %Condition{name: "enabled", display: "Enabled"},
             %Condition{name: "created_at", display: "2026-07-01 – 2026-07-10"}
           ] = state.conditions
  end

  test "keeps blank definitions available without making them active" do
    search = %Text{name: "search", value: ""}

    state =
      FilterState.new(search, [
        %Text{name: "model", label: "Model", value: "", source: %{type: :text}},
        %DateRange{
          name: "created_at",
          label: "Created at",
          value: %{},
          source: %{type: :date_range}
        }
      ])

    assert length(state.definitions) == 2
    assert state.conditions == []
    refute FilterState.any_active?(state)
  end
end
