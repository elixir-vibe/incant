defmodule Incant.Theme.Metadata do
  @moduledoc """
  Compiled metadata for an Incant theme.
  """

  @type t :: %__MODULE__{
          module: module,
          css_vars_prefix: String.t(),
          palette: atom | nil,
          accent: atom | nil,
          densities: [atom],
          tokens: keyword,
          table: keyword,
          charts: keyword,
          opts: keyword
        }

  defstruct [
    :module,
    :palette,
    :accent,
    css_vars_prefix: "--incant",
    densities: [],
    tokens: [],
    table: [],
    charts: [],
    opts: []
  ]
end
