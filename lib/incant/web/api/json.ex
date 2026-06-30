defmodule Incant.Web.API.JSON do
  @moduledoc false

  @spec cast(module(), map()) :: {:ok, struct()} | {:error, {:invalid_request, Exception.t()}}
  def cast(module, params) when is_atom(module) and is_map(params) do
    {:ok, module.from_map!(params)}
  rescue
    error in [ArgumentError, KeyError, FunctionClauseError, JSONCodec.Error] ->
      {:error, {:invalid_request, error}}
  end
end
