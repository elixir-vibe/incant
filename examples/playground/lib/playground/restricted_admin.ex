defmodule Playground.RestrictedAdmin do
  @moduledoc false

  use Incant.Admin,
    repo: Playground.Repo,
    theme: Playground.Admin.Themes.Default,
    policy: Playground.RestrictedAdmin.Policy

  resource(Playground.Admin.Resources.Product)
  dashboard(Playground.Admin.Dashboards.LLM)
end
