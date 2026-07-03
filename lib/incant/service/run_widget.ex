defmodule Incant.Service.RunWidget do
  @moduledoc "Request to run an Incant dashboard widget query."

  @type t :: %__MODULE__{
          surface_id: String.t(),
          widget_id: String.t(),
          variables: map(),
          context: map()
        }

  defstruct [:surface_id, :widget_id, variables: %{}, context: %{}]
end
