defmodule Incant.SensitiveTest do
  use ExUnit.Case, async: true

  alias Incant.Sensitive

  test "detects sensitive keyword metadata" do
    assert Sensitive.sensitive?(sensitive: true)
    assert Sensitive.sensitive?(secret: true)
    assert Sensitive.sensitive?(redacted: true)
    refute Sensitive.sensitive?(sensitive: false)
  end

  test "detects sensitive map metadata from portable contracts" do
    assert Sensitive.sensitive?(%{sensitive: true})
    assert Sensitive.sensitive?(%{secret: true})
    assert Sensitive.sensitive?(%{redacted: true})
    assert Sensitive.sensitive?(%{"sensitive" => true})
    assert Sensitive.sensitive?(%{"secret" => true})
    assert Sensitive.sensitive?(%{"redacted" => true})
    refute Sensitive.sensitive?(%{"sensitive" => false})
    refute Sensitive.sensitive?(%{})
  end

  test "redacts values for map metadata" do
    assert Sensitive.redact("sk-secret", %{"sensitive" => true}) == "[redacted]"
    assert Sensitive.redact("public", %{"sensitive" => false}) == "public"
  end
end
