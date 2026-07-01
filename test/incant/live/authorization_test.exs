defmodule Incant.Live.AuthorizationTest do
  use ExUnit.Case, async: true

  alias Incant.Admin.Metadata
  alias Incant.Live.Authorization

  defmodule Actor do
    def from_assigns(assigns), do: {:callback_actor, assigns.current_user.id}
  end

  defmodule Policy do
    use Incant.Policy

    def authorize(:allowed, _actor, _context), do: true
    def authorize(:ok, _actor, _context), do: :ok
    def authorize(:denied, _actor, _context), do: false
    def authorize(:edit, _actor, _context), do: false
    def authorize(:view_dashboard, _actor, _context), do: false
    def authorize(:reason, _actor, _context), do: {:error, :missing_role}
  end

  defmodule LocalPolicy do
    use Incant.Policy

    def authorize(:edit, _actor, _context), do: true
    def authorize(:view_dashboard, _actor, _context), do: true
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

  test "uses custom actor callback when configured" do
    admin = %Metadata{opts: [actor: {Actor, :from_assigns}]}

    assert Authorization.actor(%{current_user: %{id: 42}}, admin) == {:callback_actor, 42}
  end

  test "uses custom actor function when configured" do
    admin = %Metadata{opts: [actor: fn assigns -> assigns.current_user.email end]}

    assert Authorization.actor(%{current_user: %{email: "admin@example.com"}}, admin) ==
             "admin@example.com"
  end

  test "allows everything without a policy" do
    admin = %Metadata{opts: []}

    assert Authorization.authorize(admin, :anything, nil, %{}) == :ok
    assert Authorization.allowed?(admin, :anything, nil, %{})
  end

  test "allows service-backed sessions without local admin metadata" do
    assert Authorization.authorize(nil, :view_row, nil, %{resource: %{opts: %{}}}) == :ok
    assert Authorization.allowed?(nil, :view_row, nil, %{resource: %{opts: %{}}})
  end

  test "normalizes Bodyguard-style policy results" do
    admin = %Metadata{opts: [policy: Policy]}

    assert Authorization.authorize(admin, :allowed, nil, %{}) == :ok
    assert Authorization.authorize(admin, :ok, nil, %{}) == :ok
    assert Authorization.authorize(admin, :denied, nil, %{}) == {:error, :unauthorized}
    assert Authorization.authorize(admin, :reason, nil, %{}) == {:error, :missing_role}
  end

  test "resource policy overrides admin policy for resource actions" do
    admin = %Metadata{opts: [policy: Policy]}
    resource = %{opts: [policy: LocalPolicy]}

    assert Authorization.authorize(admin, :edit, nil, %{resource: resource}) == :ok
  end

  test "dashboard policy overrides admin policy for dashboard actions" do
    admin = %Metadata{opts: [policy: Policy]}
    dashboard = %{opts: [policy: LocalPolicy]}

    assert Authorization.authorize(admin, :view_dashboard, nil, %{dashboard: dashboard}) == :ok
  end
end
