defmodule Annon.Plugins.Scopes.SettingsValidator do
  @moduledoc """
  Validation rules for Scopes plugin settings.
  """
  import Annon.Plugin.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, settings_validation_schema())
  end

  def settings_validation_schema do
    %{
      "type" => "object",
      "required" => ["strategy"],
      "additionalProperties" => false,
      "properties" => %{
        "strategy" => %{
          "enum" => ["pcm", "jwt", "oauth2"]
        },
        "url_template" => %{
          "type" => "string"
        }
      }
    }
  end
end
