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
  Mounts Incant.

  Local admin module:

      scope "/" do
        pipe_through :browser

        incant "/admin", MyApp.Admin
      end

  Service registry:

      scope "/" do
        pipe_through :browser

        incant "/admin", registry: MyApp.IncantRegistry
      end
  """
  defmacro incant(path, admin_or_opts, opts \\ []) do
    if Keyword.keyword?(admin_or_opts) do
      registry = Keyword.fetch!(admin_or_opts, :registry)
      session_name = Keyword.get(opts, :as, :incant)
      base_path = Keyword.get(opts, :base_path, path)
      root_path = if path == "", do: "/", else: path

      quote do
        live_session unquote(session_name),
          session: %{
            "__incant__" => %Incant.Live.Session{
              source: {:registry, unquote(registry)},
              base_path: unquote(base_path)
            }
          } do
          live(unquote(path <> "/:service"), Incant.Live.Admin, :index)
          live(unquote(path <> "/:service/dashboards"), Incant.Live.Admin, :dashboards)
          live(unquote(path <> "/:service/resources"), Incant.Live.Admin, :resources)
          live(unquote(path <> "/:service/datasets"), Incant.Live.Admin, :datasets)
          live(unquote(path <> "/:service/dashboards/:dashboard"), Incant.Live.Admin, :dashboard)
          live(unquote(path <> "/:service/datasets/:dataset"), Incant.Live.Admin, :dataset)
          live(unquote(path <> "/:service/resources/:resource"), Incant.Live.Admin, :resource)

          live(
            unquote(path <> "/:service/resources/:resource/new"),
            Incant.Live.Admin,
            :resource_new
          )

          live(
            unquote(path <> "/:service/resources/:resource/:id"),
            Incant.Live.Admin,
            :resource_detail
          )

          live(
            unquote(path <> "/:service/resources/:resource/:id/edit"),
            Incant.Live.Admin,
            :resource_edit
          )

          live(unquote(root_path), Incant.Live.Admin, :services)
        end
      end
    else
      admin = admin_or_opts
      session_name = Keyword.get(opts, :as, :incant)
      base_path = Keyword.get(opts, :base_path, path)

      quote do
        live_session unquote(session_name),
          session: %{
            "__incant__" => %Incant.Live.Session{
              source: {:local, unquote(admin)},
              base_path: unquote(base_path)
            }
          } do
          live(unquote(path), Incant.Live.Admin, :index)
          live(unquote(path <> "/dashboards"), Incant.Live.Admin, :dashboards)
          live(unquote(path <> "/resources"), Incant.Live.Admin, :resources)
          live(unquote(path <> "/datasets"), Incant.Live.Admin, :datasets)
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

  @doc "Deprecated alias for `incant/3`."
  defmacro incant_admin(path, admin, opts \\ []) do
    quote do
      incant(unquote(path), unquote(admin), unquote(opts))
    end
  end
end
