defmodule Incant.Router do
  @moduledoc """
  Router helpers for mounting Incant admin surfaces.
  """

  defmacro __using__(_opts \\ []) do
    quote do
      import Incant.Router
    end
  end

  @doc """
  Mounts an Incant admin LiveView.

      scope "/" do
        pipe_through :browser

        incant_admin "/admin", MyApp.Admin
      end
  """
  defmacro incant_admin(path, admin, opts \\ []) do
    session_name = Keyword.get(opts, :as, :incant)
    base_path = Keyword.get(opts, :base_path, path)

    quote do
      live_session unquote(session_name),
        session: %{"admin" => unquote(admin), "base_path" => unquote(base_path)} do
        live(unquote(path), Incant.Live.AdminLive, :index)
      end
    end
  end
end
