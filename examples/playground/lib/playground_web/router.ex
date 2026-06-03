defmodule Playground.Router do
  use Playground, :router
  use Incant.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Playground.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    get "/", Playground.PageController, :home

    incant_admin("/admin", Playground.Admin)
    incant_admin("/restricted-admin", Playground.RestrictedAdmin, as: :restricted_incant)
  end

  # Other scopes may use custom stacks.
  # scope "/api", Playground do
  #   pipe_through :api
  # end
end
