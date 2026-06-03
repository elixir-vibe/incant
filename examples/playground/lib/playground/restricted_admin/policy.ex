defmodule Playground.RestrictedAdmin.Policy do
  @moduledoc false

  use Incant.Policy

  def authorize(:view_dashboard, _actor, _context), do: false
  def authorize(:view_resource, _actor, %{resource: %{module: Playground.Admin.Resources.LLMRequest}}), do: false
  def authorize(:view_row, _actor, %{selected_row: %{id: 2}}), do: false
  def authorize(:run_action, _actor, %{action: action}) when action in ["archive", :archive], do: false
  def authorize(_action, _actor, _context), do: true
end
