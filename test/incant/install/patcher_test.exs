defmodule Incant.Install.PatcherTest do
  use ExUnit.Case, async: true

  alias Incant.Install.Patcher

  test "adds Incant router import" do
    router = """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router
    end
    """

    assert Patcher.ensure_router_import(router) =~ "use Incant.Router"
  end

  test "does not duplicate Incant router import" do
    router = """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router
      use Incant.Router
    end
    """

    assert router |> Patcher.ensure_router_import() |> occurrences("use Incant.Router") == 1
  end

  test "adds admin route to browser scope" do
    router = """
    defmodule MyAppWeb.Router do
      use MyAppWeb, :router

      scope "/", MyAppWeb do
        pipe_through :browser

        get "/", PageController, :home
      end
    end
    """

    assert Patcher.ensure_admin_route(router, "MyApp") =~ ~S|incant("/admin", MyApp.Admin)|
  end

  test "adds Incant Tailwind source once" do
    css = "body { color: black; }"

    patched = Patcher.ensure_incant_source(css)

    assert patched =~ ~s(@source "../deps/incant/lib";)

    assert patched
           |> Patcher.ensure_incant_source()
           |> occurrences(~s(@source "../deps/incant/lib";)) == 1
  end

  defp occurrences(content, needle) do
    content
    |> String.split(needle)
    |> length()
    |> Kernel.-(1)
  end
end
