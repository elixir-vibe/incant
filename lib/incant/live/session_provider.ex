defmodule Incant.Live.SessionProvider do
  @moduledoc false

  alias Incant.Live.Session, as: LiveSession
  alias Incant.Service.Entry

  @doc "Builds the selected Incant session from private Phoenix LiveView session data."
  @spec fetch!(map(), map()) :: Incant.Session.t()
  def fetch!(%{"__incant__" => %LiveSession{source: {:local, admin}}}, _params) do
    Incant.Session.Local.new(admin)
  end

  def fetch!(%{"__incant__" => %LiveSession{source: {:entry, %Entry{} = entry}}}, _params) do
    Incant.Service.Session.new(entry)
  end

  def fetch!(%{"__incant__" => %LiveSession{source: {:registry, registry}}}, %{
        "service" => service
      }) do
    registry
    |> registry_entry!(service)
    |> Incant.Service.Session.new()
  end

  @doc "Returns registry entries when this is a registry-backed session."
  @spec registry_entries(map()) :: [Entry.t()]
  def registry_entries(%{"__incant__" => %LiveSession{source: {:registry, registry}}}) do
    Incant.Service.RegistryServer.refresh_entries(registry)
  end

  def registry_entries(_session), do: []

  @doc "Returns local admin metadata when this is a local admin session."
  @spec local_admin(map()) :: Incant.Admin.Metadata.t() | nil
  def local_admin(%{"__incant__" => %LiveSession{source: {:local, admin}}}),
    do: Incant.metadata(admin)

  def local_admin(_session), do: nil

  @doc "Returns the selected LiveView base path."
  @spec base_path(map(), map()) :: String.t()
  def base_path(%{"__incant__" => %LiveSession{base_path: base_path, source: {:registry, _}}}, %{
        "service" => service
      }) do
    base_path
    |> Path.join(URI.encode(to_string(service), &URI.char_unreserved?/1))
    |> absolute_path()
  end

  def base_path(%{"__incant__" => %LiveSession{base_path: base_path}}, _params),
    do: absolute_path(base_path)

  def base_path(_session, _params), do: "/admin"

  defp absolute_path("/"), do: "/"
  defp absolute_path(<<"/", _rest::binary>> = path), do: path
  defp absolute_path(path), do: "/" <> path

  defp registry_entry!(registry, service) do
    registry
    |> Incant.Service.RegistryServer.refresh_entries()
    |> Enum.find(&(to_string(&1.key) == to_string(service)))
    |> case do
      nil -> raise ArgumentError, "unknown Incant service: #{inspect(service)}"
      entry -> entry
    end
  end
end
