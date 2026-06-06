defmodule Incant.Policy do
  @moduledoc """
  Behaviour for Incant admin authorization policies.

  Policies receive an action, the current actor from the host Phoenix app, and
  an Incant context map. Return `true`/`:ok` to allow or `false`/`:error`/
  `{:error, reason}` to deny.

  Authorization actions use these context keys:

    * `:view_admin` - `%{admin: admin, actor: actor}`
    * `:view_resource` - `%{resource: resource}`
    * `:view_dashboard` - `%{dashboard: dashboard}`
    * `:view_row` - `%{resource: resource, selected_row: row}`
    * `:create` - `%{resource: resource, attrs: attrs}` during submit
    * `:edit` - `%{resource: resource, row: row, attrs: attrs}` during submit
    * `:run_action` - `%{resource: resource, action: action, row: row}`

  `scope_query/4` and `scope_rows/4` are optional hooks used by resource row
  loading before table/detail rendering.
  """

  @callback authorize(action :: atom(), actor :: term(), context :: map()) ::
              true | :ok | false | :error | {:error, term()}

  @callback scope_query(
              actor :: term(),
              resource :: Incant.Resource.Metadata.t(),
              queryable :: term(),
              context :: map()
            ) :: term()
  @callback scope_rows(
              actor :: term(),
              resource :: Incant.Resource.Metadata.t(),
              rows :: [term()],
              context :: map()
            ) :: [term()]

  @optional_callbacks scope_query: 4, scope_rows: 4

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Incant.Policy
    end
  end
end
