defmodule Incant.Session.Local do
  @moduledoc """
  Local BEAM-backed Incant admin session.

  This is the local implementation of the same session interface that remote
  SafeRPC service sessions implement. UI code should call the `Incant.Session`
  protocol functions and not branch on this struct directly.
  """

  @type t :: %__MODULE__{
          admin: module(),
          contract: Incant.Admin.Contract.t(),
          context: map()
        }

  defstruct [:admin, :contract, context: %{}]

  @doc "Builds a local session from an Incant admin module."
  @spec new(module(), keyword()) :: t()
  def new(admin, opts \\ []) when is_atom(admin) do
    %__MODULE__{
      admin: admin,
      contract: Incant.Admin.describe(admin),
      context: Keyword.get(opts, :context, %{})
    }
  end
end

defimpl Incant.Session, for: Incant.Session.Local do
  alias Incant.Service.Runtime

  def contract(%{contract: contract}), do: contract

  def list_surfaces(session, opts) do
    kind = Keyword.get(opts, :kind, :all)

    session
    |> surfaces_by_kind(kind)
    |> Enum.map(&Map.put_new(&1, :service, session.contract.service))
  end

  def fetch_surface(session, surface_id, opts) do
    session
    |> list_surfaces(opts)
    |> Enum.find(&(to_string(&1.id) == to_string(surface_id)))
    |> case do
      nil -> {:error, {:unknown_surface, surface_id}}
      surface -> {:ok, surface}
    end
  end

  def index(session, surface_id, params, context, _opts) do
    Runtime.index(session.admin, to_string(surface_id), params, session_context(session, context))
  end

  def read(session, surface_id, id, context, _opts) do
    Runtime.read(session.admin, to_string(surface_id), id, session_context(session, context))
  end

  def run_action(session, surface_id, action_id, payload, context, _opts) do
    Runtime.run_action(
      session.admin,
      to_string(surface_id),
      to_string(action_id),
      payload,
      session_context(session, context)
    )
  end

  def run_widget(session, surface_id, widget_id, variables, context, _opts) do
    Runtime.run_widget(
      session.admin,
      to_string(surface_id),
      to_string(widget_id),
      variables,
      session_context(session, context)
    )
  end

  defp surfaces_by_kind(session, :all) do
    session.contract.resources ++ session.contract.dashboards ++ session.contract.datasets
  end

  defp surfaces_by_kind(session, :resource), do: session.contract.resources
  defp surfaces_by_kind(session, :dashboard), do: session.contract.dashboards
  defp surfaces_by_kind(session, :dataset), do: session.contract.datasets

  defp surfaces_by_kind(_session, kind),
    do: raise(ArgumentError, "unknown surface kind: #{inspect(kind)}")

  defp session_context(%{context: base}, override), do: Map.merge(base, override)
end
