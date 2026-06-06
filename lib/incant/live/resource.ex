defmodule Incant.Live.Resource do
  @moduledoc false

  use Phoenix.Component

  alias Incant.Live.Resource.{Detail, Form, Header, Table}

  attr(:context, Incant.Live.Context, required: true)

  def view(assigns) do
    context = assigns.context

    assigns =
      assigns
      |> assign(:resource, context.resource)
      |> assign(:base_path, context.base_path)
      |> assign(:form_mode, context.form_mode)
      |> assign(:form_record, context.form_record)
      |> assign(:form_changeset, context.form_changeset)

    ~H"""
    <section class="space-y-3">
      <Header.view context={@context} />
      <Form.view :if={@form_mode} resource={@resource} record={@form_record} changeset={@form_changeset} mode={@form_mode} base_path={@base_path} />
      <Detail.view context={@context} />
      <Table.view context={@context} />
    </section>
    """
  end
end
