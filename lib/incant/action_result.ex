defmodule Incant.ActionResult do
  @moduledoc """
  Semantic results returned by Incant actions.

  Action callbacks can return these structs directly or use shorthand returns such as
  `:ok`, `"Done"`, `{:ok, "Done"}`, or `{:error, "Nope"}`. Live adapters decide how
  to apply each result.
  """

  defmodule Toast do
    @moduledoc "A user-visible notification."
    defstruct [:message, level: :info]
  end

  defmodule Error do
    @moduledoc "A user-visible action error."
    defstruct [:message]
  end

  defmodule Refresh do
    @moduledoc "Refresh one or more semantic targets."
    defstruct targets: [:surface]
  end

  defmodule Navigate do
    @moduledoc "Navigate to a route."
    defstruct [:to, mode: :patch]
  end

  defmodule Download do
    @moduledoc "Expose a prepared download."
    defstruct [:id, :label, meta: %{}]
  end

  defmodule Job do
    @moduledoc "Expose a background job created by an action."
    defstruct [:id, :label, meta: %{}]
  end

  defmodule OpenSurface do
    @moduledoc "Open another semantic Incant surface."
    defstruct [:surface, meta: %{}]
  end

  def normalize(result, opts \\ [])
  def normalize(%Toast{} = result, _opts), do: result
  def normalize(%Error{} = result, _opts), do: result
  def normalize(%Refresh{} = result, _opts), do: result
  def normalize(%Navigate{} = result, _opts), do: result
  def normalize(%Download{} = result, _opts), do: result
  def normalize(%Job{} = result, _opts), do: result
  def normalize(%OpenSurface{} = result, _opts), do: result
  def normalize(:ok, opts), do: toast(completion_message(opts))
  def normalize({:ok, result}, opts), do: normalize_ok(result, opts)
  def normalize({:error, result}, _opts), do: error(result)
  def normalize(message, _opts) when is_binary(message), do: toast(message)
  def normalize(_result, opts), do: toast(completion_message(opts))

  def toast(message, level \\ :info), do: %Toast{message: to_string(message), level: level}
  def error(%Error{} = result), do: result
  def error(message), do: %Error{message: to_string(message)}

  def refresh(targets \\ [:surface]), do: %Refresh{targets: List.wrap(targets)}
  def navigate(to, opts \\ []), do: %Navigate{to: to, mode: Keyword.get(opts, :mode, :patch)}

  def download(id, opts \\ []),
    do: %Download{id: id, label: opts[:label], meta: opts[:meta] || %{}}

  def job(id, opts \\ []), do: %Job{id: id, label: opts[:label], meta: opts[:meta] || %{}}

  def open_surface(surface, opts \\ []),
    do: %OpenSurface{surface: surface, meta: opts[:meta] || %{}}

  defp normalize_ok(result, opts) do
    if result_struct?(result), do: result, else: normalize(result, opts)
  end

  defp result_struct?(%struct{}) do
    struct in [Toast, Error, Refresh, Navigate, Download, Job, OpenSurface]
  end

  defp result_struct?(_result), do: false

  defp completion_message(opts) do
    action = Keyword.fetch!(opts, :action)
    params = Keyword.get(opts, :params, %{})

    case {Map.get(action, :scope), params} do
      {:row, %{id: id}} -> "#{action.name} action completed for #{id}"
      _other -> "#{action.name} action completed"
    end
  end
end
