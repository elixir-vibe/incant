defmodule Incant.OptionsTest do
  use ExUnit.Case, async: true

  alias Incant.Options

  test "normalizes value-to-label maps in label order" do
    assert Options.normalize(%{
             "openrouter" => "OpenRouter",
             "openai-codex" => "OpenAI Codex",
             "anthropic" => "Anthropic"
           }) == [
             %{label: "Anthropic", value: "anthropic"},
             %{label: "OpenAI Codex", value: "openai-codex"},
             %{label: "OpenRouter", value: "openrouter"}
           ]
  end

  test "normalizes ordered keyword options with string values" do
    assert Options.normalize(draft: "Draft", pending: "Pending review", active: "Active") == [
             %{label: "Draft", value: "draft"},
             %{label: "Pending review", value: "pending"},
             %{label: "Active", value: "active"}
           ]
  end

  test "supports rich option maps, tuples, and inferred values" do
    assert Options.normalize([
             %{value: "legacy", label: "Legacy", disabled: true},
             {"OpenAI", "openai"},
             :api_key
           ]) == [
             %{value: "legacy", label: "Legacy", disabled: true},
             %{label: "OpenAI", value: "openai"},
             %{label: "API key", value: "api_key"}
           ]
  end

  test "uses configurable naming for inferred values" do
    assert Options.normalize([:openai_api], terms: %{openai: "OpenAI"}) == [
             %{label: "OpenAI API", value: "openai_api"}
           ]
  end
end
