defmodule Incant.Web do
  @moduledoc false

  @doc "Static paths served by the standalone Incant endpoint."
  def static_paths, do: ~w(assets favicon.ico robots.txt)
end
