defmodule Playground.PageController do
  use Playground, :controller

  def home(conn, _params) do
    admin = Incant.metadata(Playground.Admin)
    resources = Enum.map(admin.resources, &Incant.metadata/1)
    dashboards = Enum.map(admin.dashboards, &Incant.metadata/1)
    theme = Incant.metadata(admin.opts[:theme])

    render(conn, :home, admin: admin, resources: resources, dashboards: dashboards, theme: theme)
  end
end
