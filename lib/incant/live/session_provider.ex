defmodule Incant.Live.SessionProvider do
  @moduledoc """
  Builds Incant session values for LiveView/router integration.

  LiveView should render through `Incant.Session` and not care whether the
  session is backed by a local admin module or a service registry entry.
  """

  alias Incant.Service.Entry

  @doc "Builds the Incant session value from Phoenix LiveView session data."
  @spec fetch!(map()) :: Incant.Session.t()
  def fetch!(%{"incant_session" => session}), do: session

  def fetch!(%{"admin" => admin}) when is_atom(admin) do
    Incant.Session.Local.new(admin)
  end

  def fetch!(%{"incant_entry" => %Entry{} = entry}) do
    Incant.Service.Session.new(entry)
  end

  @doc "Returns local admin metadata when this is a local admin session."
  @spec local_admin(map()) :: Incant.Admin.Metadata.t() | nil
  def local_admin(%{"admin" => admin}) when is_atom(admin), do: Incant.metadata(admin)
  def local_admin(_session), do: nil
end
