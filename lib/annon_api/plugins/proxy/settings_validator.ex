defmodule Annon.Plugins.Proxy.SettingsValidator do
  @moduledoc """
  Validation rules for Proxy plugin settings.
  """
  import Annon.Validators.JsonSchema

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_via_json_schema(changeset, :settings, %{
      "type" => "object",
      "required" => ["host"],
      "additionalProperties" => false,
      "properties" => %{
        "strip_api_path" => %{
          "type" => "boolean"
        },
        "additional_headers" => %{
          "type" => "array",
          "uniqueItems" => true,
          "items" => %{
            "type" => "string"
          }
        },
        "scheme" => %{
          "enum" => ["http", "https"]
        },
        "host" => %{
          "type" => "string",
          "oneOf" => [
            %{"format" => "hostname"},
            %{"format" => "ipv4"}
          ]
        },
        "port" => %{
          "type" => "integer"
        },
        "path" => %{
          "type" => "string",
          "pattern" => "^/.*"
        },
        "strip_api_path" => %{
          "type" => "boolean"
        },
        "additional_headers" => %{
          "type" => "array",
          "items" => %{
            "type" => "object"
          }
        }
      },
    })
  end
end
