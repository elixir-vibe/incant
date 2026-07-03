defmodule Incant.UI.Surfaces.ServiceIndex do
  @moduledoc """
  Incant registry landing surface listing discovered services.
  """

  defstruct [:id, :title, :base_path, services: [], regions: []]
end
