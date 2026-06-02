defmodule Playground.Admin do
  @moduledoc false

  use Incant.Admin,
    repo: Playground.Repo,
    theme: Playground.Admin.Themes.Default

  resource(Playground.Admin.Resources.Product)
  resource(Playground.Admin.Resources.LLMRequest)

  dashboard(Playground.Admin.Dashboards.LLM)
end
