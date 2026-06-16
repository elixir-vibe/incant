defmodule Incant.Session.Delegate do
  @moduledoc false

  defmacro __using__(opts) do
    target = Keyword.fetch!(opts, :to)

    quote do
      def contract(session), do: unquote(target).contract(session)
      def list_surfaces(session, opts), do: unquote(target).list_surfaces(session, opts)

      def fetch_surface(session, surface_id, opts),
        do: unquote(target).fetch_surface(session, surface_id, opts)

      def index(session, surface_id, params, context, opts),
        do: unquote(target).index(session, surface_id, params, context, opts)

      def read(session, surface_id, id, context, opts),
        do: unquote(target).read(session, surface_id, id, context, opts)

      def run_action(session, surface_id, action_id, payload, context, opts),
        do: unquote(target).run_action(session, surface_id, action_id, payload, context, opts)
    end
  end
end
