defmodule IncantPlaygroundWeb.Router do
  use IncantPlaygroundWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {IncantPlaygroundWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    get "/", IncantPlaygroundWeb.PageController, :home

    live_session :incant,
      session: %{"admin" => IncantPlayground.Admin, "base_path" => "/admin"} do
      live "/admin", Incant.Live.AdminLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", IncantPlaygroundWeb do
  #   pipe_through :api
  # end
end
