defmodule Incant.Service.Index do
  @moduledoc "Request to index an Incant surface."

  @table_keys %{
    "page" => :page,
    "page_size" => :page_size,
    "search" => :search,
    "sort" => :sort,
    "filters" => :filters
  }

  @type table_state :: %{
          optional(:page) => pos_integer() | String.t(),
          optional(:page_size) => pos_integer() | String.t(),
          optional(:search) => String.t(),
          optional(:sort) => String.t(),
          optional(:filters) => map()
        }

  @type t :: %__MODULE__{
          surface_id: String.t(),
          params: table_state(),
          context: map()
        }

  defstruct [:surface_id, params: %{}, context: %{}]

  @doc false
  @spec cast_params(map()) :: {:ok, table_state()} | {:error, term()}
  def cast_params(params) when is_map(params) do
    Enum.reduce_while(params, {:ok, %{}}, fn {key, value}, {:ok, table} ->
      with {:ok, field} <- table_field(key),
           {:ok, value} <- cast_field(field, value) do
        {:cont, {:ok, Map.put(table, field, value)}}
      else
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  def cast_params(other), do: {:error, {:invalid_table_state, other}}

  @doc false
  @spec dump_params(table_state()) :: map()
  def dump_params(params) do
    Map.new(params, fn {key, value} -> {to_string(key), value} end)
  end

  defp table_field(key) when is_atom(key), do: table_field(Atom.to_string(key))

  defp table_field(key) when is_binary(key) do
    case Map.fetch(@table_keys, key) do
      {:ok, field} -> {:ok, field}
      :error -> {:error, {:unknown_table_field, key}}
    end
  end

  defp table_field(key), do: {:error, {:unknown_table_field, key}}

  defp cast_field(field, value) when field in [:page, :page_size] do
    case Integer.parse(to_string(value)) do
      {integer, ""} when integer > 0 -> {:ok, integer}
      _other -> {:error, {:invalid_table_field, field, value}}
    end
  end

  defp cast_field(:filters, value) when is_map(value), do: {:ok, value}

  defp cast_field(field, value) when field in [:search, :sort] and is_binary(value),
    do: {:ok, value}

  defp cast_field(field, value), do: {:error, {:invalid_table_field, field, value}}
end
