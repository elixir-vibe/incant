defmodule Incant.Web.API.QueryRequest do
  @moduledoc false

  use JSONCodec, fast_path: :json, strict: true

  alias Incant.Service.Index

  defstruct table: %{}, context: %{}

  @type t :: %__MODULE__{table: Index.table_state(), context: map()}

  @spec cast(map()) :: {:ok, t()} | {:error, {:invalid_request, Exception.t()}}
  def cast(params) do
    with {:ok, request} <- Incant.Web.API.JSON.cast(__MODULE__, params),
         {:ok, table} <- cast_table(request.table) do
      {:ok, %{request | table: table}}
    end
  end

  @spec cast_table(map()) ::
          {:ok, Index.table_state()} | {:error, {:invalid_request, Exception.t()}}
  def cast_table(table) do
    case Index.cast_params(table) do
      {:ok, table} ->
        {:ok, table}

      {:error, reason} ->
        error = ArgumentError.exception("invalid table query: #{inspect(reason)}")
        {:error, {:invalid_request, error}}
    end
  end
end
