defmodule Incant.Install.Patcher do
  @moduledoc false

  def ensure_router_import(content) do
    if String.contains?(content, "use Incant.Router") or
         String.contains?(content, "import Incant.Router") do
      content
    else
      String.replace(content, ~r/(use\s+[^\n]+,\s*:router\n)/, "\\1  use Incant.Router\n",
        global: false
      )
    end
  end

  def ensure_admin_route(content, namespace) do
    route = "incant_admin \"/admin\", #{namespace}.Admin"

    cond do
      String.contains?(content, "incant_admin") ->
        content

      String.contains?(content, "pipe_through :browser") ->
        String.replace(
          content,
          ~r/(scope\s+"\/"(?:,\s*[^\n]+)?\s+do\n\s+pipe_through\s+:browser\n)/,
          "\\1\n    #{route}\n",
          global: false
        )

      true ->
        content <> "\n# Add inside your browser scope:\n# #{route}\n"
    end
  end

  def ensure_incant_source(content) do
    if String.contains?(content, "@source \"../deps/incant/lib\"") do
      content
    else
      "@source \"../deps/incant/lib\";\n" <> content
    end
  end
end
