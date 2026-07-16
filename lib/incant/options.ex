defmodule Incant.Options do
  @moduledoc """
  Normalizes option declarations into portable label/value maps.
  """

  @type option :: %{required(:label) => String.t(), required(:value) => term()}

  @doc false
  def prepare(options)
  def prepare(nil), do: []

  def prepare(options) when is_map(options) do
    options
    |> Enum.map(fn {value, label} -> option(value, label) end)
    |> Enum.sort_by(& &1.label)
  end

  def prepare(options) when is_list(options) do
    if Keyword.keyword?(options) do
      Enum.map(options, fn {value, label} -> option(value, label) end)
    else
      Enum.map(options, fn
        %{label: _label, value: _value} = option -> option
        %{"label" => _label, "value" => _value} = option -> option
        {label, value} -> option(value, label)
        value -> %{label: nil, value: portable_value(value)}
      end)
    end
  end

  def prepare(_options), do: []

  @spec normalize(term(), Incant.Naming.config()) :: [option()]
  def normalize(options, naming \\ [])
  def normalize(nil, _naming), do: []

  def normalize(options, naming) when is_map(options) do
    options
    |> Enum.map(fn {value, label} -> option(value, label) end)
    |> Enum.sort_by(& &1.label)
    |> normalize(naming)
  end

  def normalize(options, naming) when is_list(options) do
    if Keyword.keyword?(options) do
      Enum.map(options, fn {value, label} -> option(value, label) end)
    else
      Enum.map(options, &normalize_option(&1, naming))
    end
  end

  def normalize(_options, _naming), do: []

  defp normalize_option(%{label: nil, value: value} = option, naming),
    do: %{option | label: Incant.Naming.label(value, naming)}

  defp normalize_option(%{label: label, value: value} = option, _naming),
    do: option |> Map.put(:label, to_string(label)) |> Map.put(:value, value)

  defp normalize_option(%{"label" => label, "value" => value} = option, _naming) do
    option
    |> Map.delete("label")
    |> Map.delete("value")
    |> Map.put(:label, to_string(label))
    |> Map.put(:value, value)
  end

  defp normalize_option({label, value}, _naming), do: option(value, label)

  defp normalize_option(value, naming),
    do: option(value, Incant.Naming.label(value, naming))

  defp option(value, label), do: %{label: to_string(label), value: portable_value(value)}

  defp portable_value(value) when is_atom(value), do: Atom.to_string(value)
  defp portable_value(value), do: value
end
