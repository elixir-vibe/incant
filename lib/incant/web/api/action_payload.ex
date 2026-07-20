defmodule Incant.Web.API.ActionPayload do
  @moduledoc """
  Action invocation payload carried inside `Incant.Web.API.ActionRunRequest`.

  Holds the target record id, optional bulk selection, caller assigns, and
  action input. Library/embedded consumers do not interact with this module.
  """

  use JSONCodec, fast_path: :json, strict: true

  defstruct id: nil, selected_ids: nil, assigns: %{}, input: %{}

  @type t :: %__MODULE__{
          id: term() | nil,
          selected_ids: [term()] | nil,
          assigns: map(),
          input: map()
        }

  @spec to_service_payload(t()) :: map()
  def to_service_payload(%__MODULE__{} = payload) do
    %{
      id: payload.id,
      selected_ids: payload.selected_ids,
      assigns: payload.assigns,
      input: payload.input
    }
  end
end
