defmodule Incant.Service.Index do
  @moduledoc "Request to index an Incant surface."

  @type t :: %__MODULE__{
          surface_id: String.t(),
          params: map(),
          context: map()
        }

  defstruct [:surface_id, params: %{}, context: %{}]
end
