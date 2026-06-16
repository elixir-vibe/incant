defmodule Incant.Admin.RPC do
  @moduledoc false

  defmacro __using__(opts) do
    service = Keyword.fetch!(opts, :service)
    version = Keyword.get(opts, :version)

    quote do
      use SafeRPC, service: unquote(service), version: unquote(version)

      @behaviour Incant.Service

      @impl Incant.Service
      def describe(context) do
        Incant.Service.Runtime.describe(__MODULE__, context)
      end

      @spec index(String.t(), map(), map()) :: {:ok, map()} | {:error, term()}
      @impl Incant.Service
      def index(surface_id, params, context) when is_binary(surface_id) do
        Incant.Service.Runtime.index(__MODULE__, surface_id, params, context)
      end

      @spec read(String.t(), term(), map()) :: {:ok, term()} | {:error, term()}
      @impl Incant.Service
      def read(surface_id, id, context) when is_binary(surface_id) do
        Incant.Service.Runtime.read(__MODULE__, surface_id, id, context)
      end

      @spec run_action(String.t(), String.t(), map(), map()) ::
              {:ok, Incant.ActionResult.t()} | {:error, term()}
      @impl Incant.Service
      def run_action(surface_id, action_id, payload, context)
          when is_binary(surface_id) and is_binary(action_id) do
        Incant.Service.Runtime.run_action(__MODULE__, surface_id, action_id, payload, context)
      end

      @rpc true
      @doc "Describe this Incant admin surface."
      @spec describe(Incant.Service.Describe.t(), map(), term()) ::
              {:ok, Incant.Admin.Contract.t()} | {:error, term()}
      def describe(%Incant.Service.Describe{context: context}, meta, state) do
        describe(__incant_rpc_context__(context, meta, state))
      end

      @rpc true
      @doc "Index an Incant surface."
      @spec index(Incant.Service.Index.t(), map(), term()) :: {:ok, map()} | {:error, term()}
      def index(%Incant.Service.Index{} = request, meta, state) do
        index(
          request.surface_id,
          request.params,
          __incant_rpc_context__(request.context, meta, state)
        )
      end

      @rpc true
      @doc "Read one item from an Incant surface."
      @spec read(Incant.Service.Read.t(), map(), term()) :: {:ok, term()} | {:error, term()}
      def read(%Incant.Service.Read{} = request, meta, state) do
        read(
          request.surface_id,
          request.id,
          __incant_rpc_context__(request.context, meta, state)
        )
      end

      @rpc true
      @doc "Run an Incant surface action."
      @spec run_action(Incant.Service.RunAction.t(), map(), term()) ::
              {:ok, Incant.ActionResult.t()} | {:error, term()}
      def run_action(%Incant.Service.RunAction{} = request, meta, state) do
        run_action(
          request.surface_id,
          request.action_id,
          request.payload,
          __incant_rpc_context__(request.context, meta, state)
        )
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
