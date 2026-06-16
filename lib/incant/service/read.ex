defmodule Incant.Service.Read do
  @moduledoc "Request to read one item from an Incant surface."

  @type t :: %__MODULE__{
          surface_id: String.t(),
          id: term(),
          context: map()
        }

  defstruct [:surface_id, :id, context: %{}]
end
