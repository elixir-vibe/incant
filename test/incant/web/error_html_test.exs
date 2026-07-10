defmodule Incant.Web.ErrorHTMLTest do
  use ExUnit.Case, async: true

  test "renders Phoenix status messages" do
    assert Incant.Web.ErrorHTML.render("404.html", %{}) == "Not Found"
    assert Incant.Web.ErrorHTML.render("500.html", %{}) == "Internal Server Error"
  end
end
