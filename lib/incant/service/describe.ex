defmodule Incant.Service.Describe do
  @moduledoc "Request to describe an Incant service."

  @type t :: %__MODULE__{context: map()}

  defstruct context: %{}
end
