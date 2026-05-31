defmodule Incant.AdminTest do
  use ExUnit.Case, async: true

  defmodule PostResource do
  end

  defmodule Dashboard do
  end

  defmodule Plugin do
  end

  defmodule Admin do
    use Incant.Admin, repo: Incant.AdminTest.Repo

    resource(PostResource)
    dashboard(Dashboard)
    plugin(Plugin)
  end

  test "compiles admin metadata" do
    metadata = Admin.__incant_admin__()

    assert metadata.module == Admin
    assert metadata.opts == [repo: Incant.AdminTest.Repo]
    assert metadata.resources == [PostResource]
    assert metadata.dashboards == [Dashboard]
    assert metadata.plugins == [Plugin]
  end
end
