defmodule Incant.Admin.RPC do
  @moduledoc false

  defmacro __using__(opts) do
    service = Keyword.fetch!(opts, :service)
    version = Keyword.get(opts, :version)
    atoms = Keyword.get(opts, :atoms, [])

    quote do
      use SafeRPC, service: unquote(service), version: unquote(version), atoms: unquote(atoms)

      @behaviour Incant.Service

      @impl Incant.Service
      def describe(context) do
        Incant.Service.Runtime.describe(__MODULE__, context)
      end

      @spec index(String.t(), map(), map()) :: {:ok, map()} | {:error, term()}
      @impl Incant.Service
      def index(surface_id, params, context) when is_binary(surface_id) do
        with {:ok, page} <- Incant.Service.Runtime.index(__MODULE__, surface_id, params, context) do
          {:ok, Incant.Service.Page.to_external(page)}
        end
      end

      @spec read(String.t(), term(), map()) :: {:ok, term()} | {:error, term()}
      @impl Incant.Service
      def read(surface_id, id, context) when is_binary(surface_id) do
        with {:ok, row} <- Incant.Service.Runtime.read(__MODULE__, surface_id, id, context) do
          {:ok, JSONCodec.dump(row)}
        end
      end

      @spec run_action(String.t(), String.t(), map(), map()) ::
              {:ok, Incant.ActionResult.t()} | {:error, term()}
      @impl Incant.Service
      def run_action(surface_id, action_id, payload, context)
          when is_binary(surface_id) and is_binary(action_id) do
        Incant.Service.Runtime.run_action(__MODULE__, surface_id, action_id, payload, context)
      end

      defp __incant_rpc_context__(context, meta, state) when is_map(context) do
        context
        |> Map.put_new(:rpc_meta, meta)
        |> Map.put_new(:rpc_state, state)
      end

      defoverridable Incant.Service
    end
  end
end
