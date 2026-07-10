defmodule Incant.Web.Router do
  @moduledoc """
  HTTP router for the standalone Incant admin release.
  """

  use Phoenix.Router
  use Incant.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {Incant.Web.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    get("/health", Incant.Web.HealthPlug, [])
    get("/favicon.ico", Incant.Web.FaviconPlug, [])
    get("/config", Incant.Web.NotFoundPlug, [])
    forward("/incant", Incant.Web.API)

    pipe_through(:browser)

    incant("", registry: Incant.Service.RegistryServer, base_path: "/")
  end
end
