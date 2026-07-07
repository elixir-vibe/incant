defmodule Incant.UI.Env do
  @moduledoc """
  Runtime environment passed to UI adapters.
  """

  alias Incant.UI.Config

  @type t :: %__MODULE__{
          adapter: module,
          admin: module | nil,
          base_path: String.t(),
          locale: String.t() | nil,
          timezone: String.t() | nil,
          density: atom,
          debug: boolean,
          theme: map | nil,
          context: map | nil,
          assigns: map
        }

  defstruct adapter: Incant.UI.Adapters.LiveView,
            admin: nil,
            base_path: "/admin",
            locale: nil,
            timezone: nil,
            density: :compact,
            debug: false,
            theme: nil,
            context: nil,
            assigns: %{}

  def new(context, assigns \\ %{}) do
    admin = admin_module(context)

    %__MODULE__{
      adapter: Config.adapter(admin),
      admin: admin,
      base_path: Map.get(context, :base_path, "/admin"),
      locale: Config.get(admin, :locale),
      timezone: Config.get(admin, :timezone),
      density: Config.get(admin, :density, :compact),
      debug: Config.get(admin, :debug, false),
      theme: Map.get(context, :theme),
      context: context,
      assigns: assigns
    }
  end

  defp admin_module(%{admin: %{module: module}}), do: module
  defp admin_module(_context), do: nil
end
