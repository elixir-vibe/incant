defmodule Incant.Service.Registry do
  @moduledoc """
  Runtime registry for remotely discovered Incant services.

  The registry is the central-admin side of the HostKit/SafeRPC/Incant flow:

    * HostKit provides an ETF binding term path in `HOSTKIT_RPC_BINDINGS`.
    * Incant decodes the term with `:erlang.binary_to_term(binary, [:safe])`.
    * SafeRPC descriptors identify modules exposing the Incant service shape.
    * Incant calls `describe` for each service and stores the resulting contract.

  No service-specific modules are hardcoded by the central Incant admin.
  """

  alias Incant.Service
  alias Incant.Service.Entry

  @default_env "HOSTKIT_RPC_BINDINGS"

  @type t :: %__MODULE__{
          source: {:env, String.t(), Path.t()} | {:file, Path.t()} | :bindings,
          bindings: SafeRPC.local_bindings() | [SafeRPC.local_binding()],
          entries: [Entry.t()]
        }

  defstruct source: :bindings, bindings: %{}, entries: []

  @doc "Loads a registry from the `HOSTKIT_RPC_BINDINGS` environment variable."
  @spec load(keyword()) :: {:ok, t()} | {:error, term()}
  def load(opts \\ []) do
    env = Keyword.get(opts, :env, @default_env)

    with {:ok, path} <- fetch_env(env),
         {:ok, registry} <- load_file(path, opts) do
      {:ok, %{registry | source: {:env, env, path}}}
    end
  end

  @doc "Loads a registry from a HostKit/SafeRPC binding ETF file."
  @spec load_file(Path.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def load_file(path, opts \\ []) when is_binary(path) do
    with {:ok, binary} <- File.read(path),
         {:ok, bindings} <- decode_bindings(binary),
         {:ok, registry} <- from_bindings(bindings, opts) do
      {:ok, %{registry | source: {:file, path}}}
    else
      {:error, %File.Error{} = error} -> {:error, error}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Builds a registry from an already decoded HostKit/SafeRPC binding term."
  @spec from_bindings(SafeRPC.local_bindings() | [SafeRPC.local_binding()], keyword()) ::
          {:ok, t()} | {:error, term()}
  def from_bindings(bindings, opts \\ []) do
    context = Keyword.get(opts, :context, %{})

    with {:ok, entries} <- discover_entries(bindings, context, opts) do
      {:ok, %__MODULE__{bindings: bindings, entries: entries}}
    end
  end

  @doc "Safely decodes a HostKit/SafeRPC local binding ETF term."
  @spec decode_bindings(binary()) :: {:ok, SafeRPC.local_bindings()} | {:error, term()}
  def decode_bindings(binary) when is_binary(binary) do
    {:ok, :erlang.binary_to_term(binary, [:safe])}
  rescue
    error in [ArgumentError] -> {:error, error}
  end

  defp fetch_env(env) do
    case System.fetch_env(env) do
      {:ok, path} when path != "" -> {:ok, path}
      {:ok, ""} -> {:error, {:empty_env, env}}
      :error -> {:error, {:missing_env, env}}
    end
  end

  defp discover_entries(bindings, context, opts) do
    bindings
    |> normalize_bindings()
    |> Enum.reduce_while({:ok, []}, fn {key, binding}, {:ok, entries} ->
      case discover_binding(key, binding, context, opts) do
        {:ok, discovered} -> {:cont, {:ok, Enum.reverse(discovered, entries)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, entries} -> {:ok, Enum.reverse(entries)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp discover_binding(key, binding, context, opts) do
    with {:ok, clients} <- Service.discover([binding], opts) do
      clients
      |> Enum.reduce_while({:ok, []}, fn client, {:ok, entries} ->
        case Service.describe(client, %Service.Describe{context: context}) do
          {:ok, contract} ->
            entry = %Entry{key: key, client: client, contract: contract, binding: binding}
            {:cont, {:ok, [entry | entries]}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)
      |> case do
        {:ok, entries} -> {:ok, Enum.reverse(entries)}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp normalize_bindings(bindings) when is_map(bindings), do: Map.to_list(bindings)
  defp normalize_bindings(bindings) when is_list(bindings), do: Enum.map(bindings, &{nil, &1})
end
