defmodule Annon.Plugins.JWT.SettingsValidator do
  @moduledoc """
  Validation rules for JWT plugin settings.
  """
  import Ecto.Changeset
  alias Ecto.Changeset

  # TODO: Replace validation with JSON Schema
  def validate_settings(%Changeset{changes: %{settings: settings}} = changeset) do
    {%{}, %{signature: :string}}
    |> cast(settings, [:signature])
    |> validate_required([:signature])
    |> put_changeset_errors(changeset)
  end

  defp put_changeset_errors(%Changeset{valid?: true}, ch), do: ch
  defp put_changeset_errors(%Changeset{valid?: false, errors: errors}, ch) do
    ch
    |> Map.merge(%{errors: errors, valid?: false})
  end
end
