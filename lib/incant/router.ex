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
        live(unquote(path), Incant.Live.Admin, :index)
        live(unquote(path <> "/dashboards/:dashboard"), Incant.Live.Admin, :dashboard)
        live(unquote(path <> "/datasets/:dataset"), Incant.Live.Admin, :dataset)
        live(unquote(path <> "/resources/:resource"), Incant.Live.Admin, :resource)
        live(unquote(path <> "/resources/:resource/new"), Incant.Live.Admin, :resource_new)
        live(unquote(path <> "/resources/:resource/:id"), Incant.Live.Admin, :resource_detail)

        live(
          unquote(path <> "/resources/:resource/:id/edit"),
          Incant.Live.Admin,
          :resource_edit
        )
      end
    end
  end
end
