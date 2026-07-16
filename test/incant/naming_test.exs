defmodule Incant.NamingTest do
  use ExUnit.Case, async: false

  alias Incant.Naming

  defmodule Resource do
    use Incant.Resource, title: "API Credentials"

    table do
      column(:api_key_id)
      filter(:provider, :select, options: %{"openai" => "OpenAI"})
      action(:refresh_oauth, callback: :refresh_oauth)
    end

    def refresh_oauth(_params, _assigns), do: :ok
  end

  defmodule Admin do
    use Incant.Admin,
      service: :llm_proxy,
      version: "1",
      naming: [terms: %{openai: "OpenAI", github: "GitHub"}]

    resource(Resource)
  end

  setup do
    original = Application.get_env(:incant, :naming)

    on_exit(fn ->
      if original,
        do: Application.put_env(:incant, :naming, original),
        else: Application.delete_env(:incant, :naming)
    end)

    :ok
  end

  test "preserves technical acronyms in sentence and title styles" do
    assert Naming.label(:api_key_id) == "API key ID"
    assert Naming.title(:api_key_id) == "API Key ID"
    assert Naming.label(:llm_proxy) == "LLM proxy"
    assert Naming.title(:llm_proxy) == "LLM Proxy"
    assert Naming.label(:ttft_ms) == "TTFT ms"
    assert Naming.title("LLMProxy") == "LLM Proxy"
    assert Naming.title("APIKey") == "API Key"
  end

  test "preserves explicit display text verbatim" do
    assert Naming.label("LLM Proxy") == "LLM Proxy"
    assert Naming.title("Time to First Token") == "Time to First Token"
    assert Naming.label("openai/gpt-5.3") == "openai/gpt-5.3"
  end

  test "supports configurable phrase vocabulary and removing defaults" do
    naming = [
      terms: %{
        openai: "OpenAI",
        live_view: "LiveView",
        quack_db: "QuackDB",
        ram: false
      }
    ]

    assert Naming.label(:openai_api, naming) == "OpenAI API"
    assert Naming.label(:live_view_status, naming) == "LiveView status"
    assert Naming.title(:quack_db_console, naming) == "QuackDB Console"
    assert Naming.label(:ram_usage, naming) == "Ram usage"
  end

  test "merges global and admin vocabulary with admin precedence" do
    Application.put_env(:incant, :naming, terms: %{openai: "Open AI", github: "GitHub"})

    naming = [terms: %{openai: "OpenAI"}]

    assert Naming.label(:github_url, naming) == "GitHub URL"
    assert Naming.label(:openai_api, naming) == "OpenAI API"
  end

  test "can disable the default vocabulary" do
    assert Naming.title(:api_key, use_defaults: false) == "Api Key"
  end

  test "resolves labels and titles before crossing the contract boundary" do
    contract = Incant.Admin.describe(Admin)
    assert contract.opts.title == "LLM Proxy"

    assert [%{title: "API Credentials"} = resource] = contract.resources
    assert [%{opts: %{label: "API key ID"}}] = resource.table.columns

    assert [%{opts: %{label: "Provider", options: options}}] = resource.table.filters
    assert options == [%{label: "OpenAI", value: "openai"}]

    assert [%{opts: %{label: "Refresh OAuth"}}] = resource.table.actions
  end
end
