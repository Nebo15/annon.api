defmodule Annon.Plugins.JWT.SettingsValidator do
  @moduledoc """
  Validation rules for JWT plugin settings.
  """
  import Annon.Validators.JsonSchema

  def validate_settings(%Ecto.Changeset{} = changeset) do
    validate_via_json_schema(changeset, :settings, %{
      "type" => "object",
      "required" => ["signature"],
      "additionalProperties" => false,
      "properties" => %{
        "signature" => %{
          "type" => "string"
        },
      },
    })
  end
end
