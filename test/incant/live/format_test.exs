defmodule Incant.Live.FormatTest do
  use ExUnit.Case, async: true

  alias Incant.Live.Format

  test "formats numbers with thousands separators" do
    assert Format.value(2_752_554, :number) == "2,752,554"
    assert Format.value(-2_752_554, :number) == "-2,752,554"
    assert Format.value(12_345.67, :number) == "12,345.67"
    assert Format.value(Decimal.new("1234567.89"), :number) == "1,234,567.89"
  end

  test "formats compact numbers with scaled suffixes" do
    assert Format.value(0, :compact_number) == "0"
    assert Format.value(537, :compact_number) == "537"
    assert Format.value(1_500, :compact_number) == "1,500"
    assert Format.value(12_749, :compact_number) == "12.7k"
    assert Format.value(117_338_154, :compact_number) == "117.3M"
    assert Format.value(2_752_554, :compact_number) == "2.8M"
    assert Format.value(1_250_000_000, :compact_number) == "1.3B"
    assert Format.value(1_000_000, :compact_number) == "1M"
    assert Format.value(-2_752_554, :compact_number) == "-2.8M"
    assert Format.value(Decimal.new("117338154"), :compact_number) == "117.3M"
  end

  test "formats currency with stable decimals and separators" do
    assert Format.value(12, :money) == "$12"
    assert Format.value(12_345.6, :money) == "$12,345.60"
    assert Format.value(Decimal.new("12345.67"), :currency) == "$12,345.67"
  end

  test "formats datetimes with minute precision" do
    datetime = ~U[2026-07-01 15:55:42Z]
    naive = ~N[2026-07-01 15:55:42]

    assert Format.value(datetime, :datetime) == "2026-07-01 15:55"
    assert Format.value(naive, :datetime) == "2026-07-01 15:55"
    assert Format.value("2026-07-01T15:55:42Z", :datetime) == "2026-07-01 15:55"
    assert Format.value("2026-07-01T15:55:42", :datetime) == "2026-07-01 15:55"
  end

  test "formats date and time without subseconds" do
    assert Format.value(~D[2026-07-01], :date) == "2026-07-01"
    assert Format.value(~U[2026-07-01 15:55:42.123456Z], :date) == "2026-07-01"
    assert Format.value("2026-07-01T15:55:42Z", :date) == "2026-07-01"

    assert Format.value(~T[15:55:42.123456], :time) == "15:55:42"
    assert Format.value(~U[2026-07-01 15:55:42.123456Z], :time) == "15:55:42"
    assert Format.value("2026-07-01T15:55:42Z", :time) == "15:55:42"
  end

  test "formats booleans, identifiers, and percentages" do
    assert Format.value(true, :boolean) == "Yes"
    assert Format.value(false, :boolean) == "No"
    assert Format.value("27dca8e9-9d57-4ef2-8c5e-7dab93e3bbd3", :id) == "27dca8e9…"
    assert Format.value("short", :id) == "short"
    assert Format.value(0.1234, :percent) == "12.34%"
  end

  test "formats relative timestamps" do
    assert Format.value(DateTime.utc_now() |> DateTime.add(-3, :minute), :relative) == "3m ago"
    assert Format.value(DateTime.utc_now() |> DateTime.add(-2, :hour), :relative) == "2h ago"
    assert Format.value(DateTime.utc_now() |> DateTime.add(-5, :day), :relative) == "5d ago"
  end

  test "falls back without raising" do
    assert Format.value(nil, :number) == ""
    assert Format.value("not-a-date", :datetime) == "not-a-date"
    assert Format.value(%{unexpected: :value}, :datetime) == "%{unexpected: :value}"
  end
end
