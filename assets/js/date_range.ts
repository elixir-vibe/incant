export interface DateRange {
  from: string;
  to: string;
}

export function localDateValue(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function recentDateRange(days: number, now = new Date()): DateRange {
  const to = new Date(now);
  const from = new Date(to);
  from.setDate(to.getDate() - Math.max(days - 1, 0));

  return { from: localDateValue(from), to: localDateValue(to) };
}
