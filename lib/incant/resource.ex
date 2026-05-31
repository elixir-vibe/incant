defmodule Incant.Resource do
  @moduledoc """
  Defines a code-first admin resource.
  """

  alias Incant.Resource.Metadata
  alias Incant.Table
  alias Incant.Table.{Column, Filter}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Incant.Resource

      Module.register_attribute(__MODULE__, :incant_resource_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_columns, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :incant_filters, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :incant_table_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_search, persist: false)
      Module.register_attribute(__MODULE__, :incant_query, persist: false)

      @incant_resource_opts opts
      @before_compile Incant.Resource
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :incant_resource_opts) || []
    columns = env.module |> Module.get_attribute(:incant_columns) |> Enum.reverse()
    filters = env.module |> Module.get_attribute(:incant_filters) |> Enum.reverse()

    table = %Table{
      columns:
        Enum.map(columns, fn {name, column_opts} -> %Column{name: name, opts: column_opts} end),
      filters:
        Enum.map(filters, fn {name, type, filter_opts} ->
          %Filter{name: name, type: type, opts: filter_opts}
        end),
      search: Module.get_attribute(env.module, :incant_search),
      opts: Module.get_attribute(env.module, :incant_table_opts) || []
    }

    metadata = %Metadata{
      module: env.module,
      schema: Keyword.get(opts, :schema),
      repo: Keyword.get(opts, :repo),
      query: Module.get_attribute(env.module, :incant_query),
      table: table,
      opts: opts
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_resource__, do: unquote(escaped)
    end
  end

  defmacro table(opts \\ [], do: block) do
    quote do
      @incant_table_opts unquote(opts)
      unquote(block)
    end
  end

  defmacro column(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_columns {name, opts}
    end
  end

  defmacro filter(name, type \\ :auto, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      @incant_filters {name, type, opts}
    end
  end

  defmacro search(callback_or_fields) do
    quote bind_quoted: [callback_or_fields: callback_or_fields] do
      @incant_search callback_or_fields
    end
  end

  defmacro query(callback) do
    quote bind_quoted: [callback: callback] do
      @incant_query callback
    end
  end
end
