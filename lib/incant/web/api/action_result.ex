defmodule Incant.Web.API.ActionResult do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  @derive Jason.Encoder
  defstruct [:type, :message, :level, :targets, :to, :mode, :id, :label, :meta, :surface]

  @type type :: :toast | :error | :refresh | :navigate | :download | :job | :open_surface

  @type t :: %__MODULE__{
          type: type(),
          message: String.t() | nil,
          level: atom() | nil,
          targets: [atom()] | nil,
          to: String.t() | nil,
          mode: atom() | nil,
          id: term(),
          label: String.t() | nil,
          meta: map() | nil,
          surface: term()
        }

  codec(:type,
    atom: {:enum, [:toast, :error, :refresh, :navigate, :download, :job, :open_surface]}
  )

  codec(:level, atom: :existing)
  codec(:mode, atom: :existing)
  codec(:targets, type: {:list, :atom})

  @spec from_incant(Incant.ActionResult.t()) :: t()
  def from_incant(%Incant.ActionResult.Toast{} = result) do
    %__MODULE__{type: :toast, message: result.message, level: result.level}
  end

  def from_incant(%Incant.ActionResult.Error{} = result),
    do: %__MODULE__{type: :error, message: result.message}

  def from_incant(%Incant.ActionResult.Refresh{} = result),
    do: %__MODULE__{type: :refresh, targets: result.targets}

  def from_incant(%Incant.ActionResult.Navigate{} = result),
    do: %__MODULE__{type: :navigate, to: result.to, mode: result.mode}

  def from_incant(%Incant.ActionResult.Download{} = result),
    do: %__MODULE__{type: :download, id: result.id, label: result.label, meta: result.meta}

  def from_incant(%Incant.ActionResult.Job{} = result),
    do: %__MODULE__{type: :job, id: result.id, label: result.label, meta: result.meta}

  def from_incant(%Incant.ActionResult.OpenSurface{} = result),
    do: %__MODULE__{type: :open_surface, surface: result.surface, meta: result.meta}
end
