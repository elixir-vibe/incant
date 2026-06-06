defmodule Incant.UI.Config do
  @moduledoc """
  Reads Incant UI configuration.

  App-wide defaults live under `config :incant, ...`. Per-admin overrides live
  under `config :incant, MyApp.Admin, ...`.
  """

  @default_adapter Incant.UI.Adapters.LiveView

  def adapter(admin \\ nil), do: get(admin, :ui_adapter, @default_adapter)

  def get(admin, key, default \\ nil) do
    admin
    |> scoped_config()
    |> Keyword.get(key, Keyword.get(app_config(), key, default))
  end

  defp app_config, do: Application.get_all_env(:incant)
  defp scoped_config(nil), do: []

  defp scoped_config(admin) do
    case Application.get_env(:incant, admin, []) do
      opts when is_list(opts) -> opts
      _value -> []
    end
  end
end
