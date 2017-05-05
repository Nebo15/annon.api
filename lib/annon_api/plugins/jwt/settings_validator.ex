defmodule Annon.Plugins.JWT.SettingsValidator do
  @moduledoc """
  Validation rules for JWT plugin settings.
  """
  import Annon.Helpers.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, settings_validation_schema())
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
end
