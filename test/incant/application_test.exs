defmodule Incant.ApplicationTest do
  use ExUnit.Case, async: false

  setup do
    old_serve = Application.get_env(:incant, :serve?)
    old_registry = Application.get_env(:incant, :registry)

    on_exit(fn ->
      restore_env(:serve?, old_serve)
      restore_env(:registry, old_registry)
    end)
  end

  test "library mode starts no children by default" do
    Application.delete_env(:incant, :serve?)
    Application.delete_env(:incant, :registry)

    assert Incant.Application.children() == []
  end

  test "standalone mode starts registry and endpoint" do
    Application.put_env(:incant, :serve?, true)
    Application.put_env(:incant, :registry, name: MyRegistry)

    assert [registry, Incant.Web.Endpoint] = Incant.Application.children()
    assert {Incant.Service.RegistryServer, opts} = registry
    assert opts[:name] == MyRegistry
    assert opts[:allow_empty]
  end

  defp restore_env(key, nil), do: Application.delete_env(:incant, key)
  defp restore_env(key, value), do: Application.put_env(:incant, key, value)
end
