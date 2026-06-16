defmodule Incant.Live.Session do
  @moduledoc false

  @type source ::
          {:local, module()}
          | {:entry, Incant.Service.Entry.t()}
          | {:registry, GenServer.server()}

  @type t :: %__MODULE__{
          source: source(),
          base_path: String.t()
        }

  defstruct [:source, base_path: "/admin"]
end
