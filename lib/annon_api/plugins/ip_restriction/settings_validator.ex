defmodule Annon.Plugins.IPRestriction.SettingsValidator do
  @moduledoc """
  Validation rules for IPRestriction plugin settings.
  """
  import Annon.Plugin.JsonSchemaValidator

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_with_json_schema(changeset, :settings, settings_validation_schema())
  end

  def settings_validation_schema do
    %{
      "type" => "object",
      "anyOf" => [
        %{"required" => ["whitelist", "blacklist"]},
        %{"required" => ["whitelist"]},
        %{"required" => ["blacklist"]}
      ],
      "additionalProperties" => false,
      "properties" => %{
        "whitelist" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "oneOf" => [
              %{"pattern" => "^(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)(\/\\d{1,2})?$"}
            ]
          }
        },
        "blacklist" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "oneOf" => [
              %{"pattern" => "^(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)(\/\\d{1,2})?$"}
            ]
          }
        }
      }
    }
  end
end
