defmodule Incant.Theme do
  @moduledoc """
  Defines Tailwind 4 and CSS-variable-first theme metadata.
  """

  alias Incant.Theme.Metadata

  defmacro __using__(opts \\ []) do
    quote bind_quoted: [opts: opts] do
      import Incant.Theme

      Module.register_attribute(__MODULE__, :incant_theme_opts, persist: false)
      Module.register_attribute(__MODULE__, :incant_theme_css_vars_prefix, persist: false)
      Module.register_attribute(__MODULE__, :incant_theme_palette, persist: false)
      Module.register_attribute(__MODULE__, :incant_theme_accent, persist: false)
      Module.register_attribute(__MODULE__, :incant_theme_densities, persist: false)

      Module.register_attribute(__MODULE__, :incant_theme_tokens,
        accumulate: true,
        persist: false
      )

      Module.register_attribute(__MODULE__, :incant_theme_table, persist: false)
      Module.register_attribute(__MODULE__, :incant_theme_charts, persist: false)

      @incant_theme_opts opts
      @before_compile Incant.Theme
    end
  end

  defmacro __before_compile__(env) do
    metadata = %Metadata{
      module: env.module,
      css_vars_prefix:
        Module.get_attribute(env.module, :incant_theme_css_vars_prefix) || "--incant",
      palette: Module.get_attribute(env.module, :incant_theme_palette),
      accent: Module.get_attribute(env.module, :incant_theme_accent),
      densities: Module.get_attribute(env.module, :incant_theme_densities) || [],
      tokens: env.module |> Module.get_attribute(:incant_theme_tokens) |> Enum.reverse(),
      table: Module.get_attribute(env.module, :incant_theme_table) || [],
      charts: Module.get_attribute(env.module, :incant_theme_charts) || [],
      opts: Module.get_attribute(env.module, :incant_theme_opts) || []
    }

    escaped = Macro.escape(metadata)

    quote do
      @doc false
      def __incant_theme__, do: unquote(escaped)
    end
  end

  defmacro css_vars_prefix(prefix) do
    quote bind_quoted: [prefix: prefix] do
      @incant_theme_css_vars_prefix prefix
    end
  end

  defmacro palette(name) do
    quote bind_quoted: [name: name] do
      @incant_theme_palette name
    end
  end

  defmacro accent(name) do
    quote bind_quoted: [name: name] do
      @incant_theme_accent name
    end
  end

  defmacro density(values) do
    quote bind_quoted: [values: values] do
      @incant_theme_densities List.wrap(values)
    end
  end

  defmacro tokens(do: block), do: block

  defmacro color(name, value), do: token(:color, name, value)
  defmacro radius(name, value), do: token(:radius, name, value)
  defmacro spacing(name, value), do: token(:spacing, name, value)
  defmacro font(name, value), do: token(:font, name, value)

  defmacro table(opts, do: block) when is_list(opts) do
    quote do
      @incant_theme_table unquote(opts)
      unquote(block)
    end
  end

  defmacro table(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro charts(opts, do: block) when is_list(opts) do
    quote do
      @incant_theme_charts unquote(opts)
      unquote(block)
    end
  end

  defmacro charts(do: block) do
    quote do
      unquote(block)
    end
  end

  defmacro sticky_header(value) do
    quote bind_quoted: [value: value] do
      @incant_theme_table Keyword.put(@incant_theme_table || [], :sticky_header, value)
    end
  end

  defmacro row_height(value) do
    quote bind_quoted: [value: value] do
      @incant_theme_table Keyword.put(@incant_theme_table || [], :row_height, value)
    end
  end

  defmacro zebra(value) do
    quote bind_quoted: [value: value] do
      @incant_theme_table Keyword.put(@incant_theme_table || [], :zebra, value)
    end
  end

  defmacro chart_palette(values) do
    quote bind_quoted: [values: values] do
      @incant_theme_charts Keyword.put(@incant_theme_charts || [], :palette, values)
    end
  end

  defp token(kind, name, value) do
    quote bind_quoted: [kind: kind, name: name, value: value] do
      @incant_theme_tokens {kind, name, value}
    end
  end
end
