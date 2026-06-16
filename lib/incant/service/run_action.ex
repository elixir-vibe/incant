defmodule Incant.Service.RunAction do
  @moduledoc "Request to run an Incant surface action."

  @type t :: %__MODULE__{
          surface_id: String.t(),
          action_id: String.t(),
          payload: map(),
          context: map()
        }

  defstruct [:surface_id, :action_id, payload: %{}, context: %{}]
end
