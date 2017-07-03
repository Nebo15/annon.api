defmodule Annon.Plugins.ACL.SettingsValidator do
  @moduledoc """
  Validation rules for ACL plugin settings.
  """
  import Annon.Plugin.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, settings_validation_schema())
  end

  def settings_validation_schema do
    %{
      "type" => "object",
      "required" => ["rules"],
      "additionalProperties" => false,
      "properties" => %{
        "rules" => %{
          "type" => "array",
          "minItems" => 1,
          "uniqueItems" => true,
          "items" => %{
            "type" => "object",
            "required" => ["methods", "path", "scopes"],
            "properties" => %{
              "methods" => %{
                "type" => "array",
                "minItems" => 1,
                "items" => %{
                  "type" => "string",
                  "enum" => ["GET", "POST", "PUT", "DELETE", "PATCH"]
                }
              },
              "path" => %{
                "type" => "string",
                "pattern" => "^(?!\\^).*",
                "minLength" => 1
              },
              "scopes" => %{
                "type" => "array",
                "minItems" => 1,
                "items" => %{
                  "type" => "string"
                }
              }
            }
          }
        }
      }
    }
  end
end
