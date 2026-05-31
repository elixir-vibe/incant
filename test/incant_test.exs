defmodule IncantTest do
  use ExUnit.Case, async: true

  test "raises for modules without Incant metadata" do
    assert_raise ArgumentError, fn -> Incant.metadata(String) end
  end
end
