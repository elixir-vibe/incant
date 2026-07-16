defmodule Incant.Service.Registry do
  @moduledoc """
  Runtime registry for remotely discovered Incant services.

  The registry is the central-admin side of the HostKit/SafeRPC/Incant flow:

    * HostKit provides an ETF binding term path in `HOSTKIT_RPC_BINDINGS`.
    * Incant decodes the local HostKit-generated term from a trusted file.
    * SafeRPC descriptors identify modules exposing the Incant service shape.
    * Incant calls `describe` for each service and stores the resulting contract.

  No service-specific modules are hardcoded by the central Incant admin.
  """

  alias Incant.Service
  alias Incant.Service.Entry

  @default_env "HOSTKIT_RPC_BINDINGS"
  @binding_keys %{
    "listener" => :listener,
    "modules" => :modules,
    "socket" => :socket,
    "unit" => :unit,
    "upstream" => :upstream
  }
  @binding_atom_keys Map.values(@binding_keys)

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

  @doc "Decodes a trusted local HostKit/SafeRPC binding ETF term."
  @spec decode_bindings(binary()) :: {:ok, SafeRPC.local_bindings()} | {:error, term()}
  def decode_bindings(binary) when is_binary(binary) do
    binary
    |> :erlang.binary_to_term([:safe])
    |> normalize_decoded_bindings()
  rescue
    error in [ArgumentError] -> {:error, error}
  end

  defp normalize_decoded_bindings(bindings) when is_map(bindings) do
    bindings
    |> Enum.reduce_while({:ok, %{}}, fn {key, binding}, {:ok, normalized} ->
      case normalize_binding(binding) do
        {:ok, binding} -> {:cont, {:ok, Map.put(normalized, key, binding)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp normalize_decoded_bindings(bindings) when is_list(bindings) do
    bindings
    |> Enum.reduce_while({:ok, []}, fn binding, {:ok, normalized} ->
      case normalize_binding(binding) do
        {:ok, binding} -> {:cont, {:ok, [binding | normalized]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp normalize_decoded_bindings(other), do: {:error, {:invalid_bindings, other}}

  defp normalize_binding(binding) when is_map(binding) do
    with {:ok, binding} <- canonical_binding_keys(binding) do
      normalize_binding_modules(binding)
    end
  end

  defp normalize_binding(other), do: {:error, {:invalid_binding, other}}

  defp canonical_binding_keys(binding) do
    Enum.reduce_while(binding, {:ok, %{}}, fn {key, value}, {:ok, canonical} ->
      case canonical_binding_key(key) do
        {:ok, key} -> {:cont, {:ok, Map.put(canonical, key, value)}}
        :error -> {:halt, {:error, {:invalid_binding_key, key}}}
      end
    end)
  end

  defp canonical_binding_key(key) when is_binary(key), do: Map.fetch(@binding_keys, key)

  defp canonical_binding_key(key) when key in @binding_atom_keys, do: {:ok, key}
  defp canonical_binding_key(_key), do: :error

  defp normalize_binding_modules(%{modules: modules} = binding) when is_list(modules) do
    if Enum.all?(modules, &(is_atom(&1) or is_binary(&1))) do
      module_names = SafeRPC.Atoms.names(modules)

      with :ok <-
             SafeRPC.Atoms.prepare(module_names,
               allow: [~r/^Elixir\.[A-Z][A-Za-z0-9_.]*$/]
             ) do
        normalized_modules =
          Enum.map(modules, fn
            module when is_atom(module) -> module
            module when is_binary(module) -> String.to_existing_atom(module)
          end)

        {:ok, %{binding | modules: normalized_modules}}
      end
    else
      {:error, {:invalid_modules, modules}}
    end
  end

  defp normalize_binding_modules(binding), do: {:ok, binding}

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
