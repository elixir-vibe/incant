defmodule Incant.Live.Resource.FormTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias Incant.Form.Field
  alias Incant.Live.Resource.Form

  test "renders enum-style select fields" do
    html =
      render_component(&Form.form_field/1,
        field: %Field{name: :status, type: :select, opts: [options: [:active, :draft]]},
        value: :active,
        errors: []
      )

    assert html =~ ~s(<select)
    assert html =~ ~s(value="active" selected)
  end

  test "renders datetime fields as datetime-local" do
    html =
      render_component(&Form.form_field/1,
        field: %Field{name: :published_at, type: :datetime, opts: []},
        value: ~U[2026-05-31 12:34:56Z],
        errors: []
      )

    assert html =~ ~s(type="datetime-local")
    assert html =~ ~s(value="2026-05-31T12:34:56")
    assert html =~ ~s(step="1")
  end

  test "renders time and decimal-like number fields with useful steps" do
    time_html =
      render_component(&Form.form_field/1,
        field: %Field{name: :opens_at, type: :time, opts: []},
        value: ~T[09:30:15],
        errors: []
      )

    number_html =
      render_component(&Form.form_field/1,
        field: %Field{name: :price, type: :number, opts: []},
        value: Decimal.new("12.34"),
        errors: []
      )

    assert time_html =~ ~s(type="time")
    assert time_html =~ ~s(value="09:30:15")
    assert time_html =~ ~s(step="1")
    assert number_html =~ ~s(type="number")
    assert number_html =~ ~s(step="any")
  end
end
