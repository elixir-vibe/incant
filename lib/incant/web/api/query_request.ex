defmodule Incant.Web.API.QueryRequest do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  defstruct table: %{}, context: %{}

  @type t :: %__MODULE__{table: map(), context: map()}

  @spec cast(map()) :: {:ok, t()} | {:error, {:invalid_request, Exception.t()}}
  def cast(params), do: Incant.Web.API.JSON.cast(__MODULE__, params)
end
