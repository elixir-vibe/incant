defmodule Incant.Live.FormState do
  @moduledoc false

  def changeset(resource, record, attrs \\ %{}) do
    Incant.Forms.changeset(resource, record, attrs)
  end

  def save(_mode, %{repo: nil}, _record, _attrs), do: {:error, "Resource repo is not configured"}

  def save(_mode, %{changeset: nil}, _record, _attrs),
    do: {:error, "Resource changeset is not configured"}

  def save(mode, resource, record, attrs) when mode in [:new, :edit] do
    changeset = changeset(resource, record, attrs)
    repo_action = if mode == :new, do: :insert, else: :update

    resource.repo
    |> apply(repo_action, [changeset])
    |> normalize_save_result(mode)
  end

  defp normalize_save_result({:ok, record}, mode), do: {:ok, success_message(mode), record}
  defp normalize_save_result({:error, changeset}, _mode), do: {:error, changeset}
  defp normalize_save_result(record, mode), do: {:ok, success_message(mode), record}

  defp success_message(:new), do: "Record created"
  defp success_message(:edit), do: "Record updated"
end
