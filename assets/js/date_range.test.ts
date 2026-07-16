import { describe, expect, test } from "volt:test";
import { localDateValue, recentDateRange } from "./date_range";

describe("date range helpers", () => {
  test("formats local dates without UTC conversion", () => {
    expect(localDateValue(new Date(2026, 6, 15, 23, 30))).toBe("2026-07-15");
  });

  test("builds inclusive recent-day ranges", () => {
    expect(recentDateRange(7, new Date(2026, 6, 15, 12))).toEqual({
      from: "2026-07-09",
      to: "2026-07-15",
    });
  });

  test("clamps non-positive ranges to today", () => {
    expect(recentDateRange(0, new Date(2026, 6, 15, 12))).toEqual({
      from: "2026-07-15",
      to: "2026-07-15",
    });
  });
});
