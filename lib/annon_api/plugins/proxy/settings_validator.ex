defmodule Annon.Plugins.Proxy.SettingsValidator do
  @moduledoc """
  Validation rules for Proxy plugin settings.
  """
  import Annon.Plugin.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, settings_validation_schema())
  end

  def settings_validation_schema do
    %{
      "type" => "object",
      "required" => ["host"],
      "additionalProperties" => false,
      "properties" => %{
        "host" => %{
          "type" => "string",
          "oneOf" => [
            %{"format" => "hostname"},
            %{"format" => "ipv4"}
          ]
        },
        "scheme" => %{
          "enum" => ["http", "https"]
        },
        "port" => %{
          "type" => "integer"
        },
        "path" => %{
          "type" => "string",
          "pattern" => "^/.*",
          "minLength": 1
        },
        "strip_api_path" => %{
          "type" => "boolean"
        },
        "preserve_host" => %{
          "type" => "boolean"
        },
        "additional_headers" => %{
          "type" => "array",
          "items" => %{
            "type" => "object"
          }
        },
        "stripped_headers" => %{
          "type" => "array",
          "uniqueItems" => true,
          "items" => %{
            "type" => "string"
          }
        },
      },
    }
  end
end
