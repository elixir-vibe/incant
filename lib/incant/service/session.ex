defmodule Incant.Service.Session do
  @moduledoc """
  Admin UI session for one discovered Incant service entry.

  A session wraps `%Incant.Service.Entry{}` and exposes admin-shaped operations
  without leaking SafeRPC operation tuples or Incant service request structs into
  LiveView/rendering code.
  """

  alias Incant.Service
  alias Incant.Service.Entry
  alias Incant.Service.Index
  alias Incant.Service.Read
  alias Incant.Service.RunAction
  alias Incant.Service.RunWidget

  @type surface :: map()

  @type t :: %__MODULE__{
          entry: Entry.t(),
          context: map()
        }

  defstruct [:entry, context: %{}]

  @doc "Builds a session for a discovered service entry."
  @spec new(Entry.t(), keyword()) :: t()
  def new(%Entry{} = entry, opts \\ []) do
    %__MODULE__{entry: entry, context: Keyword.get(opts, :context, %{})}
  end

  @doc "Returns the loaded transport-safe admin contract."
  @spec contract(t()) :: Incant.Admin.Contract.t()
  def contract(%__MODULE__{entry: %Entry{contract: contract}}), do: contract

  @doc "Lists all surfaces from the loaded contract."
  @spec list_surfaces(t(), keyword()) :: [surface()]
  def list_surfaces(%__MODULE__{} = session, opts \\ []) do
    kind = Keyword.get(opts, :kind, :all)

    session
    |> surfaces_by_kind(kind)
    |> Enum.map(&Incant.Service.ContractMaterializer.surface/1)
    |> Enum.map(&Map.put_new(&1, :service, contract(session).service))
  end

  @doc "Fetches a surface by id from the loaded contract."
  @spec fetch_surface(t(), String.t() | atom(), keyword()) :: {:ok, surface()} | {:error, term()}
  def fetch_surface(%__MODULE__{} = session, surface_id, opts \\ []) do
    session
    |> list_surfaces(opts)
    |> Enum.find(&(to_string(&1.id) == to_string(surface_id)))
    |> case do
      nil -> {:error, {:unknown_surface, surface_id}}
      surface -> {:ok, surface}
    end
  end

  @doc "Indexes a remote resource surface."
  @spec index(t(), String.t() | atom(), map(), map(), keyword()) ::
          {:ok, map()} | {:error, term()}
  def index(%__MODULE__{} = session, surface_id, params \\ %{}, context \\ %{}, opts \\ []) do
    request = %Index{
      surface_id: to_string(surface_id),
      params: params,
      context: context(session, context)
    }

    with {:ok, page} <- Service.index(session.entry.client, request, opts) do
      {:ok, Incant.Service.Page.from_external(page)}
    end
  end

  @doc "Reads one remote resource item."
  @spec read(t(), String.t() | atom(), term(), map(), keyword()) ::
          {:ok, term()} | {:error, term()}
  def read(%__MODULE__{} = session, surface_id, id, context \\ %{}, opts \\ []) do
    request = %Read{
      surface_id: to_string(surface_id),
      id: id,
      context: context(session, context)
    }

    with {:ok, row} <- Service.read(session.entry.client, request, opts) do
      {:ok, Incant.Service.Row.from_external(row)}
    end
  end

  @doc "Runs an action on a remote resource surface."
  @spec run_action(t(), String.t() | atom(), String.t() | atom(), map(), map(), keyword()) ::
          {:ok, Incant.ActionResult.t()} | {:error, term()}
  def run_action(
        %__MODULE__{} = session,
        surface_id,
        action_id,
        payload \\ %{},
        context \\ %{},
        opts \\ []
      ) do
    request = %RunAction{
      surface_id: to_string(surface_id),
      action_id: to_string(action_id),
      payload: payload,
      context: context(session, context)
    }

    Service.run_action(session.entry.client, request, opts)
  end

  @doc "Runs a remote dashboard widget query."
  @spec run_widget(t(), String.t() | atom(), String.t() | atom(), map(), map(), keyword()) ::
          {:ok, term()} | {:error, term()}
  def run_widget(
        %__MODULE__{} = session,
        surface_id,
        widget_id,
        variables \\ %{},
        context \\ %{},
        opts \\ []
      ) do
    request = %RunWidget{
      surface_id: to_string(surface_id),
      widget_id: to_string(widget_id),
      variables: variables,
      context: context(session, context)
    }

    Service.run_widget(session.entry.client, request, opts)
  end

  defp surfaces_by_kind(%__MODULE__{} = session, :all) do
    contract = contract(session)
    contract.resources ++ contract.dashboards ++ contract.datasets
  end

  defp surfaces_by_kind(%__MODULE__{} = session, :resource), do: contract(session).resources
  defp surfaces_by_kind(%__MODULE__{} = session, :dashboard), do: contract(session).dashboards
  defp surfaces_by_kind(%__MODULE__{} = session, :dataset), do: contract(session).datasets

  defp surfaces_by_kind(_session, kind),
    do: raise(ArgumentError, "unknown surface kind: #{inspect(kind)}")

  defp context(%__MODULE__{context: base}, override) do
    Map.merge(base, override)
  end
end

defimpl Incant.Session, for: Incant.Service.Session do
  use Incant.Session.Delegate, to: Incant.Service.Session
end
