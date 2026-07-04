defmodule Incant.Service.Runtime do
  @moduledoc false

  alias Incant.{ActionResult, Live}

  def describe(admin, _context \\ %{}) do
    {:ok, Incant.Admin.describe(admin)}
  end

  def index(admin, surface_id, params \\ %{}, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind do
      table = Map.get(params, :table, params)
      {:ok, Live.Rows.page(surface.spec, table, service_context(admin, surface, context))}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def index_external(admin, surface_id, params \\ %{}, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind,
         {:ok, page} <- index(admin, surface_id, params, context) do
      {:ok, page |> Incant.Service.Page.from_resource_page(surface.spec) |> JSONCodec.dump()}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def read(admin, surface_id, id, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind do
      case Live.Rows.one(surface.spec, id, service_context(admin, surface, context)) do
        nil -> {:error, :not_found}
        row -> {:ok, row}
      end
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def read_external(admin, surface_id, id, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind,
         {:ok, row} <- read(admin, surface_id, id, context) do
      {:ok, Incant.Service.Row.from_resource(surface.spec, row) |> JSONCodec.dump()}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def run_action(admin, surface_id, action_id, payload \\ %{}, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :resource <- surface.kind do
      assigns = action_assigns(payload)
      id = Map.get(payload, :id)
      selected_ids = Map.get(payload, :selected_ids)
      action_context = service_context(admin, surface, context)

      result =
        cond do
          not is_nil(id) ->
            Live.Actions.run(surface.spec, to_string(action_id), id, assigns, action_context)

          is_list(selected_ids) ->
            Live.Actions.run_bulk(
              surface.spec,
              to_string(action_id),
              selected_ids,
              assigns,
              action_context
            )

          true ->
            Live.Actions.run_page(surface.spec, to_string(action_id), assigns, action_context)
        end

      {:ok, ActionResult.normalize(result)}
    else
      {:error, reason} -> {:error, reason}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  def run_widget(admin, surface_id, widget_id, variables \\ %{}, context \\ %{}) do
    with {:ok, surface} <- fetch_surface(admin, surface_id),
         :dashboard <- surface.kind,
         {:ok, widget} <- fetch_widget(surface, widget_id),
         query when not is_nil(query) <- widget.opts[:query] do
      {:ok,
       query
       |> Incant.Callback.call(variables, dashboard_context(admin, surface, variables, context))
       |> portable_widget_value()}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, {:missing_widget_query, surface_id, widget_id}}
      other -> {:error, {:unsupported_surface_kind, other}}
    end
  end

  defp action_assigns(payload) do
    assigns = Map.get(payload, :assigns, %{})
    input = Map.get(payload, :input, %{})

    case {assigns, input} do
      {assigns, input} when is_map(assigns) and input != %{} -> Map.put(assigns, :input, input)
      {assigns, _input} when is_map(assigns) -> assigns
      _ -> %{}
    end
  end

  defp fetch_surface(admin, surface_id) do
    admin
    |> Incant.Admin.surfaces()
    |> Enum.find(&(to_string(&1.id) == to_string(surface_id)))
    |> case do
      nil -> {:error, {:unknown_surface, surface_id}}
      surface -> {:ok, surface}
    end
  end

  defp fetch_widget(surface, widget_id) do
    surface.spec.widgets
    |> Enum.find(&(to_string(&1.id) == to_string(widget_id)))
    |> case do
      nil -> {:error, {:unknown_widget, surface.id, widget_id}}
      widget -> {:ok, widget}
    end
  end

  defp service_context(admin, surface, context) do
    context
    |> context_map()
    |> Map.put_new(:admin, Incant.metadata(admin))
    |> Map.put_new(:surface, surface)
    |> Map.put_new(:resource, surface.spec)
  end

  defp portable_widget_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp portable_widget_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp portable_widget_value(%Date{} = value), do: Date.to_iso8601(value)
  defp portable_widget_value(%Time{} = value), do: Time.to_iso8601(value)

  if Code.ensure_loaded?(Decimal) do
    defp portable_widget_value(%Decimal{} = value), do: Decimal.to_string(value)
  end

  defp portable_widget_value(%_struct{} = value) do
    value
    |> Map.from_struct()
    |> portable_widget_value()
  end

  defp portable_widget_value(value) when is_boolean(value) or is_nil(value), do: value

  defp portable_widget_value(value) when is_map(value) do
    Map.new(value, fn {key, value} -> {portable_widget_key(key), portable_widget_value(value)} end)
  end

  defp portable_widget_value(value) when is_list(value),
    do: Enum.map(value, &portable_widget_value/1)

  defp portable_widget_value(value) when is_tuple(value),
    do: value |> Tuple.to_list() |> portable_widget_value()

  defp portable_widget_value(value) when is_atom(value), do: Atom.to_string(value)
  defp portable_widget_value(value), do: value

  defp portable_widget_key(key) when is_atom(key), do: Atom.to_string(key)
  defp portable_widget_key(key) when is_binary(key), do: key
  defp portable_widget_key(key), do: key |> portable_widget_value() |> to_string()

  defp dashboard_context(admin, surface, variables, context) do
    admin
    |> service_context(surface, context)
    |> Map.put_new(:dashboard, surface.spec)
    |> Map.put_new(:variables, variables)
  end

  defp context_map(%_struct{} = context), do: Map.from_struct(context)
  defp context_map(context) when is_map(context), do: context
  defp context_map(_context), do: %{}
end
