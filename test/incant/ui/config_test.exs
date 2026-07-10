defmodule Incant.UI.ConfigTest do
  use ExUnit.Case, async: false

  defmodule Admin do
  end

  setup do
    app_env = Application.get_all_env(:incant)
    on_exit(fn -> restore_env(app_env) end)
    :ok
  end

  test "reads app-wide UI config" do
    Application.put_env(:incant, :ui_adapter, ExampleAdapter)
    Application.put_env(:incant, :density, :comfortable)

    assert Incant.UI.Config.adapter() == ExampleAdapter
    assert Incant.UI.Config.get(nil, :density) == :comfortable
  end

  test "admin-specific UI config overrides app defaults" do
    Application.put_env(:incant, :ui_adapter, DefaultAdapter)
    Application.put_env(:incant, Admin, ui_adapter: AdminAdapter, density: :compact)

    assert Incant.UI.Config.adapter(Admin) == AdminAdapter
    assert Incant.UI.Config.get(Admin, :density) == :compact
  end

  test "UI env reads debug mode from config" do
    Application.put_env(:incant, :debug, true)

    assert %Incant.UI.Env{debug: true} =
             Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"})
  end

  test "UI env carries Phoenix flash assigns" do
    assert %Incant.UI.Env{flash: %{info: "Saved"}} =
             Incant.UI.Env.new(%Incant.Live.Context{base_path: "/admin"}, %{
               flash: %{info: "Saved"}
             })
  end

  defp restore_env(app_env) do
    :incant
    |> Application.get_all_env()
    |> Keyword.keys()
    |> Enum.each(&Application.delete_env(:incant, &1))

    Enum.each(app_env, fn {key, value} -> Application.put_env(:incant, key, value) end)
  end
end
