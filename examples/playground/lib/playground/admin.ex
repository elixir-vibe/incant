defmodule Playground.Admin do
  @moduledoc false

  use Incant.Admin,
    repo: Playground.Repo,
    theme: Playground.Admin.Theme

  resource(Playground.Admin.ProductResource)
  resource(Playground.Admin.LLMRequestResource)

  dashboard(Playground.Admin.LLMDashboard)
end
