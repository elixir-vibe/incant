defmodule Incant.Policy do
  @moduledoc """
  Behaviour for Incant admin authorization policies.

  Policies receive an action, the current actor from the host Phoenix app, and
  an Incant context map. Return `true`/`:ok` to allow or `false`/`:error`/
  `{:error, reason}` to deny.
  """

  @callback authorize(action :: atom(), actor :: term(), context :: map()) ::
              true | :ok | false | :error | {:error, term()}

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Incant.Policy
    end
  end
end
