defmodule Incant.Web.Router do
  @moduledoc false

  use Phoenix.Router
  use Incant.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, false)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  scope "/" do
    pipe_through(:browser)

    incant("", registry: Incant.Service.RegistryServer, base_path: "/")
  end
end
