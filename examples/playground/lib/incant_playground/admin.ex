defmodule IncantPlayground.Admin do
  @moduledoc false

  use Incant.Admin,
    repo: IncantPlayground.Repo,
    theme: IncantPlayground.Admin.Theme

  resource(IncantPlayground.Admin.ProductResource)
  resource(IncantPlayground.Admin.LLMRequestResource)

  dashboard(IncantPlayground.Admin.LLMDashboard)
end
