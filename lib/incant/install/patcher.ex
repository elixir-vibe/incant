defmodule Incant.Install.Patcher do
  @moduledoc false

  def ensure_router_import(content) do
    if router_imported?(content) do
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
      incant_admin_route?(content) ->
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

  defp router_imported?(content) do
    content
    |> parse_router()
    |> ast_contains?(fn
      {:use, _meta, [{:__aliases__, _alias_meta, [:Incant, :Router]}]} -> true
      {:import, _meta, [{:__aliases__, _alias_meta, [:Incant, :Router]}]} -> true
      _node -> false
    end)
  end

  defp incant_admin_route?(content) do
    content
    |> parse_router()
    |> ast_contains?(fn
      {:incant_admin, _meta, _args} -> true
      _node -> false
    end)
  end

  defp parse_router(content), do: Sourceror.parse_string(content)

  defp ast_contains?({:ok, ast}, predicate) do
    {_ast, found?} =
      Macro.prewalk(ast, false, fn node, found? ->
        {node, found? or predicate.(node)}
      end)

    found?
  end

  defp ast_contains?(_error, _predicate), do: false

  def ensure_incant_source(content) do
    if String.contains?(content, "@source \"../deps/incant/lib\"") do
      content
    else
      "@source \"../deps/incant/lib\";\n" <> content
    end
  end
end
