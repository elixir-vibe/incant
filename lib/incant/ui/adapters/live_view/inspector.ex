defmodule Incant.UI.Adapters.LiveView.Inspector do
  @moduledoc false

  use Phoenix.Component

  import Incant.Live.Routes

  alias Incant.UI.Adapters.LiveView.Theme
  alias Incant.UI.Regions.Inspector

  attr(:inspector, Inspector, required: true)
  attr(:env, :map, required: true)

  def inspector(assigns) do
    ~H"""
    <div class={Theme.slot(:panel, :root, kind: :inspector)}>
      <div class={Theme.slot(:panel, :header)}>
        <div>
          <p class={Theme.slot(:widget, :eyebrow)}>Detail</p>
          <h3 class={Theme.slot(:page_header, :title)}>{@inspector.title}</h3>
        </div>
        <.link patch={resource_path(@env.base_path, @env.context.resource)} class={Theme.slot(:button, :base, variant: :ghost, size: :xs)}>Back to list</.link>
      </div>
      <dl class={Theme.slot(:inspector, :list)}>
        <div :for={field <- @inspector.fields} class={Theme.slot(:inspector, :item)}>
          <dt class={Theme.slot(:inspector, :label)}>{field.label}</dt>
          <dd class={Theme.slot(:inspector, :value)}>{field.display}</dd>
        </div>
      </dl>
    </div>
    """
  end
end
