defmodule Incant.Install.Patcher do
  @moduledoc false

  def ensure_router_import(content) do
    cond do
      router_imported?(content) -> content
      ast = ast_insert_router_import(content) -> ast
      true -> regex_insert_router_import(content)
    end
  end

  def ensure_admin_route(content, namespace) do
    route = "incant_admin \"/admin\", #{namespace}.Admin"

    cond do
      incant_admin_route?(content) ->
        content

      ast = ast_insert_admin_route(content, namespace) ->
        ast

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

  defp ast_insert_router_import(content) do
    with {:ok, ast} <- Sourceror.parse_string(content) do
      ast
      |> update_module_body(&insert_router_import/1)
      |> Sourceror.to_string()
    end
  rescue
    _error -> nil
  end

  defp ast_insert_admin_route(content, namespace) do
    with {:ok, ast} <- Sourceror.parse_string(content) do
      route = quoted!(~s(incant_admin "/admin", #{namespace}.Admin))

      ast
      |> Macro.prewalk(fn
        {:scope, meta, args} = node -> insert_route_in_scope(node, meta, args, route)
        node -> node
      end)
      |> Sourceror.to_string()
    end
  rescue
    _error -> nil
  end

  defp insert_route_in_scope(node, meta, args, route) do
    if browser_scope?(args) do
      update_do_block({:scope, meta, args}, fn body -> insert_after_pipe_through(body, route) end)
    else
      node
    end
  end

  defp browser_scope?(args) do
    Enum.any?(args, fn
      [{{:__block__, _, [:do]}, body}] -> body_contains_pipe_through_browser?(body)
      _arg -> false
    end)
  end

  defp body_contains_pipe_through_browser?({:__block__, _meta, nodes}) do
    Enum.any?(nodes, &pipe_through_browser?/1)
  end

  defp body_contains_pipe_through_browser?(node), do: pipe_through_browser?(node)

  defp pipe_through_browser?({:pipe_through, _meta, [{:__block__, _arg_meta, [:browser]}]}),
    do: true

  defp pipe_through_browser?(_node), do: false

  defp insert_router_import(body) do
    nodes = block_nodes(body)
    {before, after_use} = Enum.split_while(nodes, fn node -> not router_use?(node) end)

    case after_use do
      [] ->
        body

      [use_node | rest] ->
        block_from_nodes(before ++ [use_node, quoted!("use Incant.Router") | rest])
    end
  end

  defp insert_after_pipe_through(body, route) do
    nodes = block_nodes(body)
    {before, after_pipe} = Enum.split_while(nodes, fn node -> not pipe_through_browser?(node) end)

    case after_pipe do
      [] -> body
      [pipe | rest] -> block_from_nodes(before ++ [pipe, route | rest])
    end
  end

  defp router_use?({:use, _meta, [_module, {:__block__, _arg_meta, [:router]}]}), do: true
  defp router_use?(_node), do: false

  defp update_module_body(
         {:defmodule, meta, [module, [{{:__block__, block_meta, [:do]}, body}]]},
         updater
       ) do
    {:defmodule, meta, [module, [{{:__block__, block_meta, [:do]}, updater.(body)}]]}
  end

  defp update_module_body({:defmodule, meta, [module, [[do: body]]]}, updater) do
    {:defmodule, meta, [module, [[do: updater.(body)]]]}
  end

  defp update_module_body(ast, _updater), do: ast

  defp update_do_block({name, meta, args}, updater) do
    {prefix, [kw]} = Enum.split(args, length(args) - 1)

    case kw do
      [{{:__block__, block_meta, [:do]}, body}] ->
        {name, meta, prefix ++ [[{{:__block__, block_meta, [:do]}, updater.(body)}]]}

      _other ->
        {name, meta, args}
    end
  end

  defp block_nodes({:__block__, _meta, nodes}), do: nodes
  defp block_nodes(node), do: [node]

  defp block_from_nodes([node]), do: node
  defp block_from_nodes(nodes), do: {:__block__, [], nodes}

  defp quoted!(code) do
    {:ok, quoted} = Code.string_to_quoted(code)
    quoted
  end

  defp regex_insert_router_import(content) do
    String.replace(content, ~r/(use\s+[^\n]+,\s*:router\n)/, "\\1  use Incant.Router\n",
      global: false
    )
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
end
