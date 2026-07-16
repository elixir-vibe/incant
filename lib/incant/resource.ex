defmodule Incant.Resource do
  @moduledoc """
  Defines a code-first admin resource.

  Resources describe table columns, filters, row actions, forms, and the data
  source used by the generic LiveView renderer.

      defmodule MyApp.Admin.Resources.Product do
        use Incant.Resource,
          schema: MyApp.Catalog.Product,
          repo: MyApp.Repo

        changeset &MyApp.Catalog.Product.changeset/2

        table do
          column :name, link: true
          column :status, as: :badge
          filter :status, :select, options: [:draft, :active]
          action :edit
        end
      end
  """

  alias Incant.Form
  alias Incant.Form.Field
  alias Incant.Resource.Metadata
  alias Incant.Table
  alias Incant.Table.{Action, Column, Filter}

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      import Incant.Resource

      Module.register_attribute(__MODULE__, :incant_resource_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_columns, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :incant_filters, accumulate: true, persist: false)
      Module.register_attribute(__MODULE__, :incant_actions, accumulate: true, persist: false)

      Module.register_attribute(__MODULE__, :incant_bulk_actions,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_page_actions,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_row_detail, persist: false)
      Module.register_attribute(__MODULE__, :incant_table_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_search, persist: false)
      Module.register_attribute(__MODULE__, :incant_query, persist: false)
      Module.register_attribute(__MODULE__, :incant_index, persist: false)
      Module.register_attribute(__MODULE__, :incant_read, persist: false)
      Module.register_attribute(__MODULE__, :incant_changeset, persist: false)
      Module.register_attribute(__MODULE__, :incant_form_opts, persist: false)

      Module.register_attribute(__MODULE__, :incant_form_fields,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_transformer_query, persist: false)

      @incant_resource_opts opts
      @before_compile Incant.Resource
    end
  end

  defmacro __before_compile__(env) do
    opts = Module.get_attribute(env.module, :incant_resource_opts) || []
    columns = env.module |> Module.get_attribute(:incant_columns) |> Enum.reverse()
    filters = env.module |> Module.get_attribute(:incant_filters) |> Enum.reverse()
    actions = env.module |> Module.get_attribute(:incant_actions) |> Enum.reverse()
    bulk_actions = env.module |> Module.get_attribute(:incant_bulk_actions) |> Enum.reverse()
    page_actions = env.module |> Module.get_attribute(:incant_page_actions) |> Enum.reverse()
    form_fields = env.module |> Module.get_attribute(:incant_form_fields) |> Enum.reverse()

    form = %Form{
      fields:
        Enum.map(form_fields, fn {name, type, field_opts} ->
          %Field{name: name, type: type, opts: field_opts}
        end),
      opts: Module.get_attribute(env.module, :incant_form_opts) || []
    }

    table = %Table{
      columns:
        Enum.map(columns, fn {name, column_opts} -> %Column{name: name, opts: column_opts} end),
      filters:
        Enum.map(filters, fn {name, type, filter_opts, query} ->
          %Filter{
            name: name,
            type: type,
            opts: normalize_filter_opts(name, filter_opts),
            query: query
          }
        end),
      actions:
        Enum.map(actions, fn {name, action_opts} ->
          %Action{name: name, scope: :row, opts: normalize_action_opts(env.module, action_opts)}
        end),
      bulk_actions:
        Enum.map(bulk_actions, fn {name, action_opts} ->
          %Action{name: name, scope: :bulk, opts: normalize_action_opts(env.module, action_opts)}
        end),
      page_actions:
        Enum.map(page_actions, fn {name, action_opts} ->
          %Action{name: name, scope: :page, opts: normalize_action_opts(env.module, action_opts)}
        end),
      row_detail: Module.get_attribute(env.module, :incant_row_detail),
      search: Module.get_attribute(env.module, :incant_search),
      opts: Module.get_attribute(env.module, :incant_table_opts) || []
    }

    metadata = %Metadata{
      id: resource_id(env.module, opts),
      module: env.module,
      schema: Keyword.get(opts, :schema),
      repo: Keyword.get(opts, :repo),
      query: Module.get_attribute(env.module, :incant_query),
      index: index_callback(env.module, Module.get_attribute(env.module, :incant_index)),
      read: read_callback(env.module, Module.get_attribute(env.module, :incant_read)),
      changeset: Module.get_attribute(env.module, :incant_changeset),
      form: form,
      table: table,
      opts: opts
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_resource__, do: unquote(escaped)
    end
  end

  def resource_id(module, opts \\ []), do: Incant.Surface.id(module, opts)

  def index_callback(module, nil) do
    if Module.defines?(module, {:index, 2}), do: {module, :index}, else: nil
  end

  def index_callback(module, callback), do: normalize_callback(module, callback)

  def read_callback(module, nil) do
    if Module.defines?(module, {:read, 2}), do: {module, :read}, else: nil
  end

  def read_callback(module, callback), do: normalize_callback(module, callback)

  def normalize_callback(module, callback) when is_atom(callback), do: {module, callback}
  def normalize_callback(_module, callback), do: callback

  def normalize_filter_opts(name, opts) do
    if Keyword.get(opts, :options) == :distinct,
      do: Keyword.put_new(opts, :options_from, name),
      else: opts
  end

  def normalize_action_opts(module, opts) do
    Enum.reduce([:callback, :available_if], opts, fn key, opts ->
      if Keyword.has_key?(opts, key),
        do: Keyword.update!(opts, key, &normalize_callback(module, &1)),
        else: opts
    end)
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
      @incant_filters {name, type, opts, Keyword.get(opts, :query)}
    end
  end

  defmacro action(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_actions {name, opts}
    end
  end

  defmacro actions(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro row(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_actions {name, opts}
    end
  end

  defmacro bulk(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_bulk_actions {name, opts}
    end
  end

  defmacro page(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_page_actions {name, opts}
    end
  end

  defmacro row_detail(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_row_detail {name, opts}
    end
  end

  defmacro changeset(callback) do
    quote bind_quoted: [callback: callback] do
      @incant_changeset callback
    end
  end

  defmacro form(opts \\ [], do: block) do
    quote do
      @incant_form_opts unquote(opts)
      unquote(block)
    end
  end

  defmacro field(name, type \\ :auto, opts \\ []) do
    quote bind_quoted: [name: name, type: type, opts: opts] do
      @incant_form_fields {name, type, opts}
    end
  end

  defmacro transformer(name, opts \\ []) do
    quote bind_quoted: [name: name, opts: opts] do
      @incant_filters {name, :transformer, opts, Keyword.get(opts, :query)}
    end
  end

  defmacro transformer(name, opts, do: block) do
    quote do
      unquote(block)
      @incant_filters {unquote(name), :transformer, unquote(opts), @incant_transformer_query}
      @incant_transformer_query nil
    end
  end

  defmacro query_transformer(callback) do
    quote bind_quoted: [callback: callback] do
      @incant_transformer_query callback
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

  defmacro index(callback) do
    quote bind_quoted: [callback: callback] do
      @incant_index callback
    end
  end

  defmacro read(callback) do
    quote bind_quoted: [callback: callback] do
      @incant_read callback
    end
  end
end
