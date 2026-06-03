defmodule Incant.Live.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Incant.Admin.Metadata
  alias Incant.Live.Authorization

  defmodule Policy do
    use Incant.Policy

    def authorize(:allowed, _actor, _context), do: true
    def authorize(:ok, _actor, _context), do: :ok
    def authorize(:denied, _actor, _context), do: false
    def authorize(:reason, _actor, _context), do: {:error, :missing_role}
  end

  test "detects Phoenix current scope before other actor assigns" do
    admin = %Metadata{opts: []}
    scope = %{user: %{id: 1}}

    assert Authorization.actor(%{current_scope: scope, current_user: %{id: 2}}, admin) == scope
  end

  test "uses explicit actor assign when configured" do
    admin = %Metadata{opts: [actor_assign: :current_admin]}

    assert Authorization.actor(%{current_user: %{id: 1}, current_admin: %{id: 2}}, admin) == %{
             id: 2
           }
  end

  test "allows everything without a policy" do
    admin = %Metadata{opts: []}

    assert Authorization.authorize(admin, :anything, nil, %{}) == :ok
    assert Authorization.allowed?(admin, :anything, nil, %{})
  end

  test "normalizes Bodyguard-style policy results" do
    admin = %Metadata{opts: [policy: Policy]}

    assert Authorization.authorize(admin, :allowed, nil, %{}) == :ok
    assert Authorization.authorize(admin, :ok, nil, %{}) == :ok
    assert Authorization.authorize(admin, :denied, nil, %{}) == {:error, :unauthorized}
    assert Authorization.authorize(admin, :reason, nil, %{}) == {:error, :missing_role}
  end
end
