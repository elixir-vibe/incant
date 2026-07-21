defmodule Incant.Naming do
  @moduledoc """
  Configurable naming for inferred Incant labels and titles.

  Explicit DSL labels and titles always take precedence. The vocabulary only
  applies when Incant must infer display text from an identifier.
  """

  @default_terms %{
    "api" => "API",
    "cli" => "CLI",
    "cpu" => "CPU",
    "css" => "CSS",
    "csv" => "CSV",
    "dns" => "DNS",
    "gpu" => "GPU",
    "html" => "HTML",
    "http" => "HTTP",
    "https" => "HTTPS",
    "id" => "ID",
    "ip" => "IP",
    "json" => "JSON",
    "llm" => "LLM",
    "o_auth" => "OAuth",
    "oauth" => "OAuth",
    "otp" => "OTP",
    "ram" => "RAM",
    "rpc" => "RPC",
    "sdk" => "SDK",
    "sql" => "SQL",
    "sse" => "SSE",
    "ssh" => "SSH",
    "ssl" => "SSL",
    "tcp" => "TCP",
    "tls" => "TLS",
    "ttft" => "TTFT",
    "ui" => "UI",
    "uri" => "URI",
    "url" => "URL",
    "usd" => "USD",
    "utc" => "UTC",
    "uuid" => "UUID",
    "vm" => "VM",
    "xml" => "XML"
  }

  @type style :: :sentence | :title
  @type config :: keyword() | map()

  @doc "Returns a sentence-style inferred label."
  @spec label(term(), config()) :: String.t()
  def label(value, naming \\ []), do: humanize(value, :sentence, naming)

  @doc "Returns a title-style inferred title."
  @spec title(term(), config()) :: String.t()
  def title(value, naming \\ []), do: humanize(value, :title, naming)

  @doc """
  Returns the display text for a value when the naming vocabulary defines an
  explicit term for it, or `nil` when it does not. Unlike `label/2`, this does
  not invent a title-cased form for unknown values, so it is safe for
  humanizing data cells without mangling identifiers and model names.
  """
  @spec term_label(term(), config()) :: String.t() | nil
  def term_label(value, naming \\ []) do
    value = to_string(value)

    if explicit_display_text?(value) do
      nil
    else
      key = value |> String.downcase() |> String.replace("-", "_")

      naming
      |> vocabulary()
      |> Map.get(key)
    end
  end

  @doc "Returns the naming options declared by an admin metadata value."
  @spec for_admin(term()) :: config()
  def for_admin(%{opts: opts}), do: option(opts, :naming, [])
  def for_admin(_admin), do: []

  @doc "Resolves inferred labels throughout a portable admin contract."
  @spec resolve_contract(Incant.Admin.Contract.t(), config()) :: Incant.Admin.Contract.t()
  def resolve_contract(%Incant.Admin.Contract{} = contract, naming \\ []) do
    resources = Enum.map(contract.resources, &resolve_resource(&1, naming))
    dashboards = Enum.map(contract.dashboards, &resolve_dashboard(&1, naming))
    datasets = Enum.map(contract.datasets, &resolve_dataset(&1, naming))

    opts =
      contract.opts
      |> Map.put_new(:title, title(contract.service || contract.id, naming))

    %{contract | resources: resources, dashboards: dashboards, datasets: datasets, opts: opts}
  end

  defp humanize(nil, _style, _naming), do: ""

  defp humanize(value, style, naming) do
    value = to_string(value)

    if explicit_display_text?(value) do
      value
    else
      value
      |> tokens()
      |> render_tokens(style, vocabulary(naming))
      |> Enum.join(" ")
    end
  end

  defp explicit_display_text?(value) do
    String.contains?(value, " ") or
      String.match?(value, ~r/[^[:alnum:]_-]/u)
  end

  defp tokens(value) do
    value
    |> String.replace(["_", "-"], " ")
    |> String.split(" ", trim: true)
    |> Enum.flat_map(&word_tokens/1)
  end

  defp word_tokens(word) do
    Regex.scan(~r/[A-Z]+(?=[A-Z][a-z]|\d|$)|[A-Z]?[a-z]+|[A-Z]+|\d+/u, word)
    |> Enum.map(fn [token] ->
      %{normalized: String.downcase(token), uppercase?: uppercase_token?(token)}
    end)
  end

  defp uppercase_token?(token) do
    String.length(token) > 1 and token == String.upcase(token) and token != String.downcase(token)
  end

  defp render_tokens(tokens, style, vocabulary) do
    terms = compiled_terms(vocabulary)
    render_tokens(tokens, style, terms, true, [])
  end

  defp render_tokens([], _style, _terms, _first?, rendered), do: Enum.reverse(rendered)

  defp render_tokens(tokens, style, terms, first?, rendered) do
    case matching_term(tokens, terms) do
      {display, length} ->
        render_tokens(Enum.drop(tokens, length), style, terms, false, [display | rendered])

      nil ->
        [token | rest] = tokens
        display = ordinary_token(token, style, first?)
        render_tokens(rest, style, terms, false, [display | rendered])
    end
  end

  defp matching_term(tokens, terms) do
    Enum.find_value(terms, fn {term_tokens, display} ->
      if Enum.take(tokens, length(term_tokens)) |> Enum.map(& &1.normalized) == term_tokens,
        do: {display, length(term_tokens)}
    end)
  end

  defp ordinary_token(%{normalized: token, uppercase?: true}, _style, _first?),
    do: String.upcase(token)

  defp ordinary_token(%{normalized: token}, :title, _first?), do: upper_first(token)
  defp ordinary_token(%{normalized: token}, :sentence, true), do: upper_first(token)
  defp ordinary_token(%{normalized: token}, :sentence, false), do: token

  defp upper_first(<<first::utf8, rest::binary>>), do: String.upcase(<<first::utf8>>) <> rest
  defp upper_first(""), do: ""

  defp vocabulary(naming) do
    global = Application.get_env(:incant, :naming, [])
    use_defaults? = option(naming, :use_defaults, option(global, :use_defaults, true))
    base = if use_defaults?, do: @default_terms, else: %{}

    base
    |> merge_terms(option(global, :terms, %{}))
    |> merge_terms(option(naming, :terms, %{}))
  end

  defp merge_terms(base, terms) do
    Enum.reduce(terms, base, fn {key, display}, vocabulary ->
      key = normalize_term_key(key)

      if display in [nil, false],
        do: Map.delete(vocabulary, key),
        else: Map.put(vocabulary, key, to_string(display))
    end)
  end

  defp compiled_terms(vocabulary) do
    vocabulary
    |> Enum.map(fn {key, display} -> {String.split(key, "_", trim: true), display} end)
    |> Enum.sort_by(fn {tokens, _display} -> -length(tokens) end)
  end

  defp normalize_term_key(key) do
    key
    |> to_string()
    |> Macro.underscore()
    |> String.replace("-", "_")
  end

  defp resolve_resource(resource, naming) do
    resource
    |> Map.update!(:table, &resolve_table(&1, naming))
    |> Map.update!(:form, &resolve_form(&1, naming))
    |> Map.update!(:title, &title(&1, naming))
  end

  defp resolve_table(table, naming) do
    table
    |> Map.update!(:columns, &Enum.map(&1, fn item -> resolve_named(item, naming) end))
    |> Map.update!(:filters, &Enum.map(&1, fn item -> resolve_options(item, naming) end))
    |> Map.update!(:actions, &Enum.map(&1, fn item -> resolve_named(item, naming) end))
    |> Map.update!(:bulk_actions, &Enum.map(&1, fn item -> resolve_named(item, naming) end))
    |> Map.update!(:page_actions, &Enum.map(&1, fn item -> resolve_named(item, naming) end))
    |> Map.update(:row_detail, nil, &resolve_optional_named(&1, naming))
  end

  defp resolve_form(form, naming) do
    Map.update!(form, :fields, &Enum.map(&1, fn item -> resolve_options(item, naming) end))
  end

  defp resolve_dashboard(dashboard, naming) do
    dashboard
    |> Map.update!(:title, &title(&1, naming))
    |> Map.update!(:variables, &Enum.map(&1, fn item -> resolve_options(item, naming) end))
    |> Map.update!(:widgets, &Enum.map(&1, fn item -> resolve_widget(item, naming) end))
  end

  defp resolve_dataset(dataset, naming) do
    dataset
    |> Map.update!(:title, &title(&1, naming))
    |> Map.update!(:filters, &Enum.map(&1, fn item -> resolve_options(item, naming) end))
  end

  defp resolve_widget(widget, naming) do
    widget = resolve_named(widget, naming)

    case Map.fetch(widget.opts, :columns) do
      {:ok, columns} ->
        put_in(widget, [:opts, :columns], Enum.map(columns, &resolve_named(&1, naming)))

      :error ->
        widget
    end
  end

  defp resolve_options(item, naming) do
    item
    |> resolve_named(naming)
    |> update_in([:opts], fn opts ->
      case Map.fetch(opts, :options) do
        {:ok, options} -> Map.put(opts, :options, Incant.Options.normalize(options, naming))
        :error -> opts
      end
    end)
  end

  defp resolve_named(%{opts: opts} = item, naming) do
    name = Map.get(item, :name, Map.get(item, :id))
    %{item | opts: Map.put_new(opts, :label, label(name, naming))}
  end

  defp resolve_optional_named(nil, _naming), do: nil
  defp resolve_optional_named(item, naming), do: resolve_named(item, naming)

  defp option(opts, key, default) when is_list(opts), do: Keyword.get(opts, key, default)

  defp option(opts, key, default) when is_map(opts),
    do: Map.get(opts, key, Map.get(opts, to_string(key), default))

  defp option(_opts, _key, default), do: default
end
