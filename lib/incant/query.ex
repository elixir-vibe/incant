defmodule Incant.Query do
  @moduledoc """
  Normalized query request passed to Incant data sources.
  """

  @type t :: %__MODULE__{
          source: atom | module | nil,
          dataset: struct | nil,
          from: term,
          dimensions: [atom],
          metrics: [atom],
          group_by: [atom],
          columns: [atom],
          drilldown: atom | nil,
          filters: map,
          sort: keyword,
          page: pos_integer | nil,
          page_size: pos_integer | nil,
          variables: map,
          context: term
        }

  defstruct source: nil,
            dataset: nil,
            from: nil,
            dimensions: [],
            metrics: [],
            group_by: [],
            columns: [],
            drilldown: nil,
            filters: %{},
            sort: [],
            page: nil,
            page_size: nil,
            variables: %{},
            context: nil
end
