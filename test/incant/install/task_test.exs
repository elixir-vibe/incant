defmodule Incant.Install.TaskTest do
  use ExUnit.Case, async: true

  alias Igniter.Test, as: IgniterTest
  alias Mix.Tasks.Incant.Install

  test "installer creates starter files and patches Phoenix files" do
    igniter =
      IgniterTest.test_project(
        files: %{
          "lib/incant_web/router.ex" => """
          defmodule IncantWeb.Router do
            use IncantWeb, :router

            scope "/", IncantWeb do
              pipe_through :browser

              get "/", PageController, :home
            end
          end
          """,
          "assets/css/app.css" => "body { color: black; }\n"
        }
      )
      |> Install.igniter()

    assert {:ok, applied, _meta} = IgniterTest.apply_igniter(igniter)

    assert_content(applied, "lib/incant/admin.ex", "defmodule Incant.Admin")

    assert_content(
      applied,
      "lib/incant/admin/resources/sample.ex",
      "defmodule Incant.Admin.Resources.Sample"
    )

    assert_content(applied, "lib/incant_web/router.ex", "use Incant.Router")
    assert_content(applied, "lib/incant_web/router.ex", ~S|incant_admin("/admin", Incant.Admin)|)
    assert_content(applied, "assets/css/app.css", ~S|@source "../deps/incant/lib";|)
  end

  defp assert_content(igniter, path, expected) do
    content = igniter.rewrite |> Rewrite.source!(path) |> Rewrite.Source.get(:content)

    assert content =~ expected
  end
end
