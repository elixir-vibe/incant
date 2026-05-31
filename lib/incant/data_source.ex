defmodule Incant.DataSource do
  @moduledoc """
  Behaviour for non-Ecto and analytical data sources.
  """

  alias Incant.{Query, Result}

  @type capability ::
          :filter
          | :sort
          | :paginate
          | :aggregate
          | :group
          | :timeseries
          | :search
          | :export
          | :live_update
          | :mutate
          | :drilldown

  @callback schema() :: term
  @callback capabilities() :: [capability]
  @callback query(Query.t()) :: {:ok, Result.t()} | {:error, term}

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Incant.DataSource

      @impl Incant.DataSource
      def schema, do: []

      @impl Incant.DataSource
      def capabilities, do: []

      defoverridable schema: 0, capabilities: 0
    end
  end
end
