defprotocol Incant.Session do
  @moduledoc """
  Unified Incant admin session interface.

  LiveView and other admin UI code should depend on this protocol rather
  than knowing whether an admin surface is backed by local BEAM metadata or a
  SafeRPC-discovered service entry.
  """

  @type t :: term()

  @doc "Returns the loaded transport-safe admin contract."
  def contract(session)

  @doc "Lists contract surfaces. Options may include `:kind`."
  def list_surfaces(session, opts)

  @doc "Fetches one contract surface by id."
  def fetch_surface(session, surface_id, opts)

  @doc "Indexes a resource surface."
  def index(session, surface_id, params, context, opts)

  @doc "Reads one resource item."
  def read(session, surface_id, id, context, opts)

  @doc "Runs a resource action."
  def run_action(session, surface_id, action_id, payload, context, opts)

  @doc "Runs a dashboard widget query."
  def run_widget(session, surface_id, widget_id, variables, context, opts)
end
