defmodule Incant.Web.API.Problem do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive Jason.Encoder
  defstruct [:type, :title, :status, :detail, :instance, :code]

  @type t :: %__MODULE__{
          type: String.t(),
          title: String.t(),
          status: pos_integer(),
          detail: String.t(),
          instance: String.t() | nil,
          code: String.t()
        }

  @spec from_reason(term(), Plug.Conn.t()) :: t()
  def from_reason(reason, conn) do
    {status, code, title, detail} = problem(reason)

    %__MODULE__{
      type: "about:blank",
      title: title,
      status: status,
      detail: detail,
      instance: conn.request_path,
      code: code
    }
  end

  @spec status(term()) :: pos_integer()
  def status(reason), do: reason |> problem() |> elem(0)

  defp problem(:not_found),
    do: {404, "not-found", "Not Found", "The requested resource was not found."}

  defp problem({:unknown_service, service}) do
    {404, "unknown-service", "Unknown service",
     "No Incant service named #{service} is registered."}
  end

  defp problem({:unknown_surface, surface}) do
    {404, "unknown-surface", "Unknown surface", "No Incant surface named #{surface} exists."}
  end

  defp problem({:unknown_action, action}) do
    {404, "unknown-action", "Unknown action", "No Incant action named #{action} exists."}
  end

  defp problem({:unknown_surface_kind, kind}) do
    {400, "unknown-surface-kind", "Unknown surface kind", "Unsupported surface kind #{kind}."}
  end

  defp problem({:invalid_request, reason}) do
    {400, "invalid-request", "Invalid request", Exception.message(reason)}
  end

  defp problem({:method_not_allowed, allow}) do
    {405, "method-not-allowed", "Method not allowed",
     "This resource supports only these HTTP methods: #{allow}."}
  end

  defp problem(:not_acceptable) do
    {406, "not-acceptable", "Not acceptable",
     "Request Accept header does not allow application/vnd.incant.admin+json."}
  end

  defp problem(:unsupported_media_type) do
    {415, "unsupported-media-type", "Unsupported media type",
     "Request Content-Type must be application/json or application/vnd.incant.admin+json."}
  end

  defp problem(reason), do: {422, "operation-failed", "Operation failed", inspect(reason)}
end
