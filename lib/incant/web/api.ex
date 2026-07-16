defmodule Incant.Web.API do
  @moduledoc """
  Strict JSON HTTP API for the standalone Incant admin release.

  The API exposes Incant's existing session contract over HTTP: service
  discovery, surface inspection, resource row/query reads, and declared action
  execution. JSON request contracts are decoded once at the boundary with
  `JSONCodec`; errors use RFC 9457 Problem Details.
  """

  use Plug.Router

  alias Incant.Service.{RegistryServer, Session}
  alias Incant.Web.API

  @default_registry Incant.Service.RegistryServer
  @media_type "application/vnd.incant.admin+json"
  @json_media_type "application/json"

  plug(:fetch_query_params)
  plug(:put_common_headers)
  plug(:negotiate_accept)

  plug(:parse_supported_body)

  plug(:match)
  plug(:dispatch)

  get "/" do
    API.Document.new(%{name: "Incant Admin API"}, links: %{services: "/incant/services"})
    |> json(conn, 200)
  end

  get "/services" do
    data = conn |> entries() |> Enum.map(&API.ServiceSummary.from_entry/1)
    API.Document.new(data, links: %{self: conn.request_path}) |> json(conn, 200)
  end

  get "/services/:service" do
    with {:ok, entry} <- fetch_entry(conn, service) do
      entry
      |> API.ServiceResource.from_entry()
      |> API.Document.new(links: service_links(service))
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  get "/services/:service/surfaces" do
    with {:ok, session} <- fetch_service_session(conn, service),
         {:ok, opts} <- surface_opts(conn.query_params) do
      session
      |> contract_surfaces(opts)
      |> API.Document.new(links: %{self: conn.request_path}, meta: %{service: service})
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  get "/services/:service/surfaces/:surface" do
    with {:ok, session} <- fetch_service_session(conn, service),
         {:ok, surface_data} <- contract_surface(session, surface) do
      surface_data
      |> API.Document.new(
        links: surface_links(service, surface),
        meta: %{service: service, surface: surface}
      )
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  get "/services/:service/surfaces/:surface/rows" do
    with {:ok, session} <- fetch_service_session(conn, service),
         {:ok, table} <- API.QueryRequest.cast_table(conn.query_params),
         {:ok, result} <- Incant.Session.index(session, surface, table, %{}, []) do
      result
      |> API.Document.new(
        links: %{self: conn.request_path},
        meta: %{service: service, surface: surface}
      )
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  post "/services/:service/surfaces/:surface/queries" do
    with :ok <- require_supported_content_type(conn),
         {:ok, request} <- API.QueryRequest.cast(conn.body_params),
         {:ok, session} <- fetch_service_session(conn, service),
         {:ok, result} <-
           Incant.Session.index(session, surface, request.table, request.context, []) do
      result
      |> API.Document.new(
        links: %{self: conn.request_path},
        meta: %{service: service, surface: surface}
      )
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  get "/services/:service/surfaces/:surface/rows/:id" do
    with {:ok, session} <- fetch_service_session(conn, service),
         {:ok, record} <- Incant.Session.read(session, surface, id, %{}, []) do
      record
      |> API.Document.new(
        links: %{self: conn.request_path},
        meta: %{service: service, surface: surface}
      )
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  get "/services/:service/surfaces/:surface/actions" do
    with {:ok, session} <- fetch_service_session(conn, service),
         {:ok, surface_data} <- contract_surface(session, surface) do
      surface_data
      |> surface_actions()
      |> API.Document.new(
        links: %{self: conn.request_path},
        meta: %{service: service, surface: surface}
      )
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  get "/services/:service/surfaces/:surface/actions/:action" do
    with {:ok, session} <- fetch_service_session(conn, service),
         {:ok, surface_data} <- contract_surface(session, surface),
         {:ok, action_data} <- fetch_surface_action(surface_data, action) do
      action_data
      |> API.Document.new(
        links: %{self: conn.request_path},
        meta: %{service: service, surface: surface}
      )
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  post "/services/:service/surfaces/:surface/actions/:action/runs" do
    with :ok <- require_supported_content_type(conn),
         {:ok, request} <- API.ActionRunRequest.cast(conn.body_params),
         {:ok, session} <- fetch_service_session(conn, service),
         {:ok, result} <-
           Incant.Session.run_action(
             session,
             surface,
             action,
             API.ActionPayload.to_service_payload(request.payload),
             request.context,
             []
           ) do
      result
      |> API.ActionRun.succeeded()
      |> API.Document.new(meta: %{service: service, surface: surface, action: action})
      |> json(conn, 200)
    else
      {:error, reason} -> problem(conn, reason)
    end
  end

  match "/" do
    method_not_allowed(conn, "GET")
  end

  match "/services" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces/:surface" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces/:surface/rows" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces/:surface/queries" do
    method_not_allowed(conn, "POST")
  end

  match "/services/:service/surfaces/:surface/rows/:id" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces/:surface/actions" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces/:surface/actions/:action" do
    method_not_allowed(conn, "GET")
  end

  match "/services/:service/surfaces/:surface/actions/:action/runs" do
    method_not_allowed(conn, "POST")
  end

  match _ do
    problem(conn, :not_found)
  end

  defp fetch_service_session(conn, service) do
    with {:ok, entry} <- fetch_entry(conn, service) do
      {:ok, Session.new(entry)}
    end
  end

  defp fetch_entry(conn, service) do
    conn
    |> entries()
    |> Enum.find(&API.ServiceSummary.matches?(&1, service))
    |> case do
      nil -> {:error, {:unknown_service, service}}
      entry -> {:ok, entry}
    end
  end

  defp entries(conn) do
    conn.private
    |> Map.get(:incant_api_registry, @default_registry)
    |> RegistryServer.list_entries()
  end

  defp contract_surfaces(session, opts) do
    contract = Incant.Session.contract(session)

    case Keyword.get(opts, :kind, :all) do
      :resource -> contract.resources
      :dashboard -> contract.dashboards
      :dataset -> contract.datasets
      :all -> contract.resources ++ contract.dashboards ++ contract.datasets
    end
  end

  defp contract_surface(session, surface_id) do
    session
    |> contract_surfaces([])
    |> Enum.find(&(to_string(&1.id) == to_string(surface_id)))
    |> case do
      nil -> {:error, {:unknown_surface, surface_id}}
      surface -> {:ok, surface}
    end
  end

  defp surface_opts(%{"kind" => "resource"}), do: {:ok, [kind: :resource]}
  defp surface_opts(%{"kind" => "dashboard"}), do: {:ok, [kind: :dashboard]}
  defp surface_opts(%{"kind" => "dataset"}), do: {:ok, [kind: :dataset]}
  defp surface_opts(%{"kind" => kind}), do: {:error, {:unknown_surface_kind, kind}}
  defp surface_opts(_query), do: {:ok, []}

  defp surface_actions(%{table: table}) when is_map(table) do
    Map.get(table, :actions, []) ++
      Map.get(table, :bulk_actions, []) ++ Map.get(table, :page_actions, [])
  end

  defp surface_actions(_surface), do: []

  defp fetch_surface_action(surface, action) do
    surface
    |> surface_actions()
    |> Enum.find(&(Map.get(&1, :id) == action))
    |> case do
      nil -> {:error, {:unknown_action, action}}
      action -> {:ok, action}
    end
  end

  defp service_links(service) do
    %{self: "/incant/services/#{service}", surfaces: "/incant/services/#{service}/surfaces"}
  end

  defp surface_links(service, surface) do
    base = "/incant/services/#{service}/surfaces/#{surface}"
    %{self: base, rows: "#{base}/rows", queries: "#{base}/queries", actions: "#{base}/actions"}
  end

  defp put_common_headers(conn, _opts) do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> put_resp_header("vary", "accept")
  end

  defp negotiate_accept(%{req_headers: headers} = conn, _opts) do
    accept = List.keyfind(headers, "accept", 0, {"accept", "*/*"}) |> elem(1)

    if media_accepted?(accept) do
      conn
    else
      conn |> problem(:not_acceptable) |> halt()
    end
  end

  defp media_accepted?(accept) do
    Enum.any?(String.split(accept, ","), fn part ->
      media = part |> String.split(";", parts: 2) |> hd() |> String.trim()
      media in ["*/*", "application/*", @json_media_type, @media_type]
    end)
  end

  defp parse_supported_body(conn, _opts) do
    if conn.method in ["POST", "PUT", "PATCH"] and request_content_type_supported?(conn) do
      Plug.Parsers.call(
        conn,
        Plug.Parsers.init(
          parsers: [:json],
          pass: [@media_type, @json_media_type, "*/*"],
          json_decoder: Jason
        )
      )
    else
      conn
    end
  end

  defp request_content_type_supported?(conn) do
    conn
    |> Plug.Conn.get_req_header("content-type")
    |> case do
      [content_type | _] -> supported_content_type?(content_type)
      [] -> false
    end
  end

  defp require_supported_content_type(conn) do
    case Plug.Conn.get_req_header(conn, "content-type") do
      [] ->
        {:error, :unsupported_media_type}

      [content_type | _] ->
        if supported_content_type?(content_type), do: :ok, else: {:error, :unsupported_media_type}
    end
  end

  defp supported_content_type?(content_type) do
    media = content_type |> String.split(";", parts: 2) |> hd() |> String.trim()
    media in [@json_media_type, @media_type]
  end

  defp method_not_allowed(conn, allow) do
    conn
    |> put_resp_header("allow", allow)
    |> problem({:method_not_allowed, allow})
  end

  defp json(%API.Document{} = document, conn, status), do: json(conn, status, document)

  defp json(conn, status, payload) do
    conn
    |> put_resp_content_type(@media_type)
    |> send_resp(status, Jason.encode!(payload))
  end

  defp problem(conn, reason) do
    status = API.Problem.status(reason)
    body = API.Problem.from_reason(reason, conn)

    conn
    |> put_resp_content_type("application/problem+json")
    |> send_resp(status, Jason.encode!(body))
  end
end
