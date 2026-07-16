defmodule Incant.Live.AdminTest do
  use ExUnit.Case, async: true

  defmodule UserResource do
    use Incant.Resource, title: "Users"

    index(&__MODULE__.index/1)
    read(&__MODULE__.read/2)

    table do
      column(:name, link: true)
      row_detail(:user)
    end

    def index(_params), do: [%{id: 1, name: "Ada"}]
    def read(id, _context), do: %{id: id, name: "Ada"}
  end

  defmodule Admin do
    use Incant.Admin, service: :accounts, version: "1", title: "Accounts"

    resource(UserResource)
  end

  test "root layout uses the assigned browser title instead of duplicating Incant" do
    template = File.read!("lib/incant/web/layouts/root.html.heex")

    assert template =~
             ~s(<.live_title suffix=" · Incant">{assigns[:page_title] || "Admin"}</.live_title>)

    refute template =~ ~s(<.live_title suffix=" · Incant">Incant</.live_title>)
  end

  test "assigns branded browser titles for resource routes" do
    socket = mounted_socket(:resource)

    assert {:noreply, socket} =
             Incant.Live.Admin.handle_params(%{"resource" => "user_resource"}, "/admin", socket)

    assert socket.assigns.page_title == "Users · Accounts"
  end

  test "assigns section-index browser titles" do
    socket = mounted_socket(:resources)

    assert {:noreply, socket} = Incant.Live.Admin.handle_params(%{}, "/admin/resources", socket)
    assert socket.assigns.page_title == "Resources · Accounts"
  end

  test "includes record and operation context in browser titles" do
    detail_socket = mounted_socket(:resource_detail)

    assert {:noreply, detail_socket} =
             Incant.Live.Admin.handle_params(
               %{"resource" => "user_resource", "id" => "1"},
               "/admin/resources/user_resource/1",
               detail_socket
             )

    assert detail_socket.assigns.page_title == "Ada · Users · Accounts"

    new_socket = mounted_socket(:resource_new)

    assert {:noreply, new_socket} =
             Incant.Live.Admin.handle_params(
               %{"resource" => "user_resource"},
               "/admin/resources/user_resource/new",
               new_socket
             )

    assert new_socket.assigns.page_title == "New User · Accounts"
  end

  defp mounted_socket(live_action) do
    socket = %Phoenix.LiveView.Socket{assigns: %{__changed__: %{}, live_action: live_action}}

    session = %{
      "__incant__" => %Incant.Live.Session{source: {:local, Admin}, base_path: "/admin"}
    }

    assert {:ok, socket} = Incant.Live.Admin.mount(%{}, session, socket)
    socket
  end
end
