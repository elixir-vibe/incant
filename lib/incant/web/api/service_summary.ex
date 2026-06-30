defmodule Incant.Web.API.ServiceSummary do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  alias Incant.Service.Entry

  @derive Jason.Encoder
  defstruct [:id, :key, :service, :version, :surfaces]

  @type t :: %__MODULE__{
          id: String.t(),
          key: String.t() | nil,
          service: String.t() | nil,
          version: String.t() | nil,
          surfaces: Incant.Web.API.SurfaceCounts.t()
        }

  @spec from_entry(Entry.t()) :: t()
  def from_entry(%Entry{} = entry) do
    %__MODULE__{
      id: id(entry),
      key: binding_key(entry),
      service: service(entry),
      version: entry.contract.version,
      surfaces: Incant.Web.API.SurfaceCounts.from_contract(entry.contract)
    }
  end

  @spec matches?(Entry.t(), String.t()) :: boolean()
  def matches?(%Entry{} = entry, candidate) when is_binary(candidate) do
    candidate in Enum.reject([id(entry), binding_key(entry), service(entry)], &is_nil/1)
  end

  @spec id(Entry.t()) :: String.t()
  def id(%Entry{} = entry), do: service(entry) || binding_key(entry) || entry.contract.id

  defp binding_key(%Entry{key: nil}), do: nil
  defp binding_key(%Entry{key: key}) when is_atom(key), do: Atom.to_string(key)
  defp binding_key(%Entry{key: key}) when is_binary(key), do: key

  defp service(%Entry{contract: %{service: service}}) when is_atom(service),
    do: Atom.to_string(service)

  defp service(%Entry{contract: %{service: service}}) when is_binary(service), do: service
  defp service(_entry), do: nil
end
