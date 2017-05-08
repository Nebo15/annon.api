defmodule Annon.Plugins.JWT.SettingsValidator do
  @moduledoc """
  Validation rules for JWT plugin settings.
  """
  import Annon.Plugin.JsonSchemaValidator
  alias Ecto.Changeset

  def validate_settings(%Changeset{} = changeset) do
    changeset
    |> validate_with_json_schema(:settings, settings_validation_schema())
    |> validate_signature()
  end

  def settings_validation_schema do
    %{
      "type" => "object",
      "required" => ["signature"],
      "additionalProperties" => false,
      "properties" => %{
        "signature" => %{
          "type" => "string"
        },
      },
    }
  end

  defp validate_signature(%Changeset{} = changeset) do
    with {:ok, %{"signature" => signature}} when is_binary(signature) <- Changeset.fetch_change(changeset, :settings),
         :error <- Base.decode64(signature) do
      Changeset.add_error(changeset, :"settings.signature", "is not Base64 encoded", validation: :cast)
    else
      _ -> changeset
    end
  end
end
