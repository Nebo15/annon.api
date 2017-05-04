defmodule Annon.Plugins.Scopes.SettingsValidator do
  @moduledoc """
  Validation rules for Scopes plugin settings.
  """
  import Annon.Helpers.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, %{
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
    })
  end
end
