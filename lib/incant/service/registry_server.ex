defmodule Incant.Service.RegistryServer do
  @moduledoc """
  Supervised process for a central Incant service registry.

  The server owns the runtime copy of `%Incant.Service.Registry{}` for a central
  Incant admin application. By default it loads from `HOSTKIT_RPC_BINDINGS`
  through `Incant.Service.Registry.load/1`, but tests and embedding apps may pass
  already decoded `:bindings` or a `:path`.
  """

  use GenServer

  alias Incant.Service.Entry
  alias Incant.Service.Registry

  @type server :: GenServer.server()

  @doc "Starts a registry server."
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    name = Keyword.get(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc "Returns the current registry snapshot."
  @spec registry(server()) :: Registry.t()
  def registry(server \\ __MODULE__), do: GenServer.call(server, :registry)

  @doc "Lists discovered entries."
  @spec list_entries(server()) :: [Entry.t()]
  def list_entries(server \\ __MODULE__), do: GenServer.call(server, :list_entries)

  @doc "Refreshes the registry and lists its entries, retaining the current snapshot on failure."
  @spec refresh_entries(server()) :: [Entry.t()]
  def refresh_entries(server \\ __MODULE__) do
    case refresh(server) do
      {:ok, registry} -> registry.entries
      {:error, _reason} -> list_entries(server)
    end
  end

  @doc "Fetches the first entry for a binding key."
  @spec get_entry(server(), Entry.binding_key()) :: Entry.t() | nil
  def get_entry(server \\ __MODULE__, key), do: GenServer.call(server, {:get_entry, key})

  @doc "Fetches the entry for a binding key and Incant service module."
  @spec get_entry(server(), Entry.binding_key(), module()) :: Entry.t() | nil
  def get_entry(server, key, module), do: GenServer.call(server, {:get_entry, key, module})

  @doc "Reloads bindings/descriptors/contracts and returns the new registry."
  @spec refresh(server()) :: {:ok, Registry.t()} | {:error, term()}
  def refresh(server \\ __MODULE__), do: GenServer.call(server, :refresh)

  @impl GenServer
  def init(opts) do
    state = %{opts: opts, registry: empty_registry()}

    case load(opts) do
      {:ok, registry} -> {:ok, %{state | registry: registry}}
      {:error, reason} -> init_error(reason, opts, state)
    end
  end

  @impl GenServer
  def handle_call(:registry, _from, state) do
    {:reply, state.registry, state}
  end

  def handle_call(:list_entries, _from, state) do
    {:reply, state.registry.entries, state}
  end

  def handle_call({:get_entry, key}, _from, state) do
    {:reply, Enum.find(state.registry.entries, &(&1.key == key)), state}
  end

  def handle_call({:get_entry, key, module}, _from, state) do
    entry = Enum.find(state.registry.entries, &(&1.key == key and &1.client.module == module))
    {:reply, entry, state}
  end

  def handle_call(:refresh, _from, state) do
    case load(state.opts) do
      {:ok, registry} -> {:reply, {:ok, registry}, %{state | registry: registry}}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  defp load(opts) do
    cond do
      bindings = Keyword.get(opts, :bindings) ->
        Registry.from_bindings(bindings, opts)

      path = Keyword.get(opts, :path) ->
        Registry.load_file(path, opts)

      true ->
        Registry.load(opts)
    end
  end

  defp init_error(reason, opts, state) do
    if Keyword.get(opts, :allow_empty, false) do
      {:ok, state}
    else
      {:stop, reason}
    end
  end

  defp empty_registry, do: %Registry{source: :bindings, bindings: %{}, entries: []}
end
