defmodule Incant.Service do
  @moduledoc """
  Behaviour for service-owned Incant admin/control-plane surfaces.

  `use Incant.Admin, rpc: true` implements this behaviour and exposes it through
  SafeRPC. Application modules should usually use the Incant admin DSL instead
  of implementing this behaviour by hand.

  Central control-plane applications can discover Incant service modules from a
  HostKit/SafeRPC binding term, then use `%Incant.Service.Client{}` handles to
  call the standard Incant service verbs without repeating SafeRPC operation
  tuples at every call site.
  """

  alias Incant.Service.Client
  alias Incant.Service.Describe
  alias Incant.Service.Index
  alias Incant.Service.Read
  alias Incant.Service.RunAction

  @required_ops [:describe, :index, :read, :run_action]

  @callback describe(context :: map()) :: {:ok, Incant.Admin.Contract.t()} | {:error, term()}
  @callback index(surface_id :: String.t(), params :: map(), context :: map()) ::
              {:ok, map()} | {:error, term()}
  @callback read(surface_id :: String.t(), id :: term(), context :: map()) ::
              {:ok, term()} | {:error, term()}
  @callback run_action(
              surface_id :: String.t(),
              action_id :: String.t(),
              payload :: map(),
              context :: map()
            ) :: {:ok, Incant.ActionResult.t()} | {:error, term()}

  @doc """
  Builds a client handle for a discovered Incant service module.

  The first argument may be a HostKit/SafeRPC local binding map containing a
  `:socket` key, or an already-started SafeRPC client process/name. Pass the
  service module with `:module`.
  """
  @spec client(SafeRPC.local_binding() | Client.endpoint(), module: module()) :: Client.t()
  def client(binding_or_endpoint, opts) do
    module = Keyword.fetch!(opts, :module)
    endpoint = endpoint(binding_or_endpoint)

    %Client{
      endpoint: endpoint,
      module: module,
      binding: binding_info(binding_or_endpoint)
    }
  end

  @doc """
  Discovers Incant service clients from HostKit/SafeRPC local bindings.

  Each binding is described through SafeRPC. Modules exposing the standard
  Incant service operation set (`describe`, `index`, `read`, `run_action`) are
  returned as `%Incant.Service.Client{}` values.
  """
  @spec discover(SafeRPC.local_bindings() | [SafeRPC.local_binding()], keyword()) ::
          {:ok, [Client.t()]} | {:error, term()}
  def discover(bindings, opts \\ []) do
    bindings
    |> binding_values()
    |> Enum.reduce_while({:ok, []}, fn binding, {:ok, clients} ->
      case discover_binding(binding, opts) do
        {:ok, discovered} -> {:cont, {:ok, Enum.reverse(discovered, clients)}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, clients} -> {:ok, Enum.reverse(clients)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Calls the remote Incant service `describe` verb."
  @spec describe(Client.t(), Describe.t(), keyword()) ::
          {:ok, Incant.Admin.Contract.t()} | {:error, term()}
  def describe(%Client{} = client, request \\ %Describe{}, opts \\ []) do
    call(client, :describe, request, opts)
  end

  @doc "Calls the remote Incant service `index` verb."
  @spec index(Client.t(), Index.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def index(%Client{} = client, %Index{} = request, opts \\ []) do
    call(client, :index, request, opts)
  end

  @doc "Calls the remote Incant service `read` verb."
  @spec read(Client.t(), Read.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def read(%Client{} = client, %Read{} = request, opts \\ []) do
    call(client, :read, request, opts)
  end

  @doc "Calls the remote Incant service `run_action` verb."
  @spec run_action(Client.t(), RunAction.t(), keyword()) ::
          {:ok, Incant.ActionResult.t()} | {:error, term()}
  def run_action(%Client{} = client, %RunAction{} = request, opts \\ []) do
    call(client, :run_action, request, opts)
  end

  defp call(%Client{endpoint: endpoint, module: module}, function, request, opts) do
    SafeRPC.call(endpoint, {module, function}, request, opts)
  end

  defp discover_binding(%{socket: socket} = binding, opts) do
    with {:ok, descriptor} <- SafeRPC.describe(socket, opts) do
      modules = Map.get(binding, :modules, Map.keys(descriptor.modules))

      clients =
        modules
        |> Enum.filter(&incant_service_module?(descriptor, &1))
        |> Enum.map(fn module ->
          %Client{
            endpoint: socket,
            module: module,
            binding: binding,
            service: descriptor.service,
            version: descriptor.version,
            descriptor: descriptor
          }
        end)

      {:ok, clients}
    end
  end

  defp discover_binding(binding, _opts), do: {:error, {:missing_socket, binding}}

  defp incant_service_module?(%SafeRPC.Descriptor{modules: modules}, module) do
    case Map.fetch(modules, module) do
      {:ok, %{ops: ops}} -> Enum.all?(@required_ops, &Map.has_key?(ops, &1))
      :error -> false
    end
  end

  defp endpoint(%{socket: socket}), do: socket
  defp endpoint(endpoint), do: endpoint

  defp binding_info(%{} = binding), do: binding
  defp binding_info(_endpoint), do: nil

  defp binding_values(bindings) when is_map(bindings), do: Map.values(bindings)
  defp binding_values(bindings) when is_list(bindings), do: bindings
end
