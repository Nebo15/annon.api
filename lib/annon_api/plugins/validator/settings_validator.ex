defmodule Annon.Plugins.Validator.SettingsValidator do
  @moduledoc """
  Validation rules for Validator plugin settings.
  """
  import Annon.Helpers.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, %{
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
            "required" => ["methods", "path", "schema"],
            "properties" => %{
              "methods" => %{
                "type" => "array",
                "minItems" => 1,
                "items" => %{
                  "type" => "string",
                  "enum" => ["POST", "PUT", "PATCH"]
                }
              },
              "path" => %{
                "type" => "string"
              },
              "schema" => %{
                "type" => "object"
              }
            }
          }
        }
      }
    })
  end
end
