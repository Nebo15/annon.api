defmodule Annon.Plugins.IPRestriction.SettingsValidator do
  @moduledoc """
  Validation rules for IPRestriction plugin settings.
  """
  import Annon.Validators.JsonSchema

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_via_json_schema(changeset, :settings, %{
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
              %{"pattern" => "^(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)$"}
            ]
          }
        },
        "blacklist" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "oneOf" => [
              %{"pattern" => "^(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)\.(\\*|\\d+)$"}
            ]
          }
        }
      }
    })
  end
end
