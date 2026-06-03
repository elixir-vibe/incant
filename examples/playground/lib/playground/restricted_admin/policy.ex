defmodule Playground.RestrictedAdmin.Policy do
  @moduledoc false

  use Incant.Policy

  def authorize(:view_dashboard, _actor, _context), do: false
  def authorize(:run_action, _actor, %{action: action}) when action in ["archive", :archive], do: false
  def authorize(_action, _actor, _context), do: true
end
