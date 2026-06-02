defmodule Incant.Callback do
  @moduledoc false

  def call(nil, _params, default), do: default
  def call(function, params, _context) when is_function(function, 1), do: function.(params)

  def call(function, params, context) when is_function(function, 2),
    do: function.(params, context)

  def call({module, function}, params, context), do: apply(module, function, [params, context])

  def call({module, function, args}, params, context),
    do: apply(module, function, [params, context | args])
end
