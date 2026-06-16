defmodule Incant.Surface do
  @moduledoc """
  Common envelope for top-level Incant admin surfaces.

  Resources, dashboards, datasets, tools, and future admin concepts are wrapped
  in a surface envelope. The envelope owns cross-cutting identity used by routes,
  navigation, public contracts, and remote transports. The `spec` field contains
  the kind-specific metadata.
  """

  @type kind :: :resource | :dashboard | :dataset | atom

  @type t :: %__MODULE__{
          kind: kind(),
          id: String.t(),
          module: module(),
          title: String.t(),
          spec: struct(),
          opts: keyword()
        }

  defstruct [:kind, :id, :module, :title, :spec, opts: []]

  @doc "Builds a stable surface id from explicit opts or module naming convention."
  @spec id(module(), keyword()) :: String.t()
  def id(module, opts \\ []) when is_atom(module) and is_list(opts) do
    opts[:id] || opts[:as] || module |> Module.split() |> List.last() |> Macro.underscore()
  end

  @doc "Builds a human title from explicit opts, metadata title, or module name."
  @spec title(module(), keyword(), String.t() | nil) :: String.t()
  def title(module, opts \\ [], title \\ nil) do
    opts[:title] || title || module |> Module.split() |> List.last()
  end
end
