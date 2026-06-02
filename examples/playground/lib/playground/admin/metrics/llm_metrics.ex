defmodule Playground.Admin.Metrics.LLM do
  @moduledoc false

  def total_requests(_params, _context), do: 12_840
  def total_cost(_params, _context), do: 184.62
  def avg_latency(_params, _context), do: 812
  def error_rate(_params, _context), do: 0.012
end
