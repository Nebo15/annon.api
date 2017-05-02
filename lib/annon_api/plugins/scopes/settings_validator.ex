defmodule Annon.Plugins.Scopes.SettingsValidator do
  @moduledoc """
  Validation rules for Scopes plugin settings.
  """
  import Annon.Validators.JsonSchema

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_via_json_schema(changeset, :settings, %{
      "type" => "object",
      "required" => ["strategy"],
      "additionalProperties" => false,
      "properties" => %{
        "strategy" => %{
          "enum" => ["pcm", "jwt"]
        },
        "url_template" => %{
          "type" => "string"
        }
      }
    })
  end
end
