defmodule Incant do
  @moduledoc """
  Code-first admin, content, analytics, and operations surfaces for Phoenix applications.

  Incant's first layer is a small set of DSLs that compile to inspectable metadata.
  Renderers and integrations can use this metadata to build LiveView admin screens,
  dashboards, resources, and plugins without taking away direct access to Ecto and
  application code.
  """

  @doc """
  Returns compiled Incant metadata from a module.
  """
  @spec metadata(module) :: struct
  def metadata(module) when is_atom(module) do
    Code.ensure_compiled(module)

    cond do
      function_exported?(module, :__incant_admin__, 0) -> module.__incant_admin__()
      function_exported?(module, :__incant_resource__, 0) -> module.__incant_resource__()
      function_exported?(module, :__incant_dataset__, 0) -> module.__incant_dataset__()
      function_exported?(module, :__incant_dashboard__, 0) -> module.__incant_dashboard__()
      function_exported?(module, :__incant_theme__, 0) -> module.__incant_theme__()
      true -> raise ArgumentError, "#{inspect(module)} does not expose Incant metadata"
    end
  end
end
