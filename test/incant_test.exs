defmodule IncantTest do
  use ExUnit.Case
  doctest Incant

  test "greets the world" do
    assert Incant.hello() == :world
  end
end
