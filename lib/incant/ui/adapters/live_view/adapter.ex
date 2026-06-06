defmodule Incant.UI.Adapters.LiveView do
  @moduledoc """
  Default Incant UI adapter backed by Phoenix LiveView components.
  """

  @behaviour Incant.UI.Adapter

  use Phoenix.Component

  alias Incant.Live.{Dashboard, Resource, Shell}
  alias Incant.UI.Document

  @impl Incant.UI.Adapter
  def render(%Document{} = document, env) do
    assigns = %{document: document, env: env, context: document.context}

    ~H"""
    <Shell.view context={@context} page_title={@document.title}>
      <.access_denied :if={match?({:error, _reason}, @context.authorization)} context={@context} />
      <Dashboard.view :if={@context.authorization == :ok and @context.section == "dashboard" and @context.dashboard} context={@context} />
      <Resource.view :if={@context.authorization == :ok and @context.section == "resource" and @context.resource} context={@context} />
    </Shell.view>
    """
  end

  def render(node, _env) do
    assigns = %{node: node}

    ~H"""
    <pre class="rounded-md border border-[var(--incant-border)] bg-[var(--incant-bg-muted)] p-3 text-xs text-[var(--incant-text-muted)]"><%= inspect(@node, pretty: true) %></pre>
    """
  end

  attr(:context, :map, required: true)

  def access_denied(assigns) do
    assigns = assign(assigns, :message, denied_message(assigns.context.authorization))

    ~H"""
    <section class="rounded-lg border border-[var(--incant-border)] bg-[var(--incant-bg-elevated)] p-6 text-center">
      <p class="text-sm text-[var(--incant-text-muted)]">Access denied</p>
      <h2 class="mt-2 text-xl font-semibold tracking-tight">{@message}</h2>
    </section>
    """
  end

  defp denied_message({:error, reason}), do: authorization_message(reason)
  defp denied_message(_authorization), do: "You are not allowed to view this admin surface."

  defp authorization_message({:unauthorized, action}), do: "Not authorized to #{action}."
  defp authorization_message(reason) when is_atom(reason), do: "Not authorized: #{reason}."
  defp authorization_message(reason), do: "Not authorized: #{inspect(reason)}."
end
