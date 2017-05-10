defmodule Annon.Plugins.CORS.SettingsValidator do
  @moduledoc """
  Validation helpers for CORS plugin.

  Original settings can be found in
  [CORSPlug source](https://github.com/mschae/cors_plug/blob/master/lib/cors_plug.ex).
  """
  import Annon.Plugin.JsonSchemaValidator

  def validate_settings(changeset) do
    validate_with_json_schema(changeset, :settings, settings_validation_schema())
  end

  def settings_validation_schema do
    %{
      "type" => "object",
      "additionalProperties" => false,
      "properties" => %{
        "origin" => %{
          "oneOf" => [
            %{"type" => "string"},
            %{"type" => "array"}
          ]
        },
        "credentials" => %{
          "type" => "boolean"
        },
        "credentials" => %{
          "type" => "number"
        },
        "headers" => %{
          "type" => "array"
        },
        "expose" => %{
          "type" => "array"
        },
        "methods" => %{
          "type" => "array"
        }
      },
    }
  end
end
