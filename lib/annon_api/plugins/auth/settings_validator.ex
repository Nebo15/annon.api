defmodule Annon.Plugins.Auth.SettingsValidator do
  @moduledoc """
  Validation helpers for Auth plugin.
  """
  import Annon.Plugin.JsonSchemaValidator
  alias Ecto.Changeset

  def validate_settings(changeset) do
    changeset
    |> validate_with_json_schema(:settings, settings_validation_schema())
    |> maybe_validate_signature()
  end

  def settings_validation_schema do
    %{
      "oneOf" => [
        %{
          "type" => "object",
          "additionalProperties" => false,
          "requiredProperties" => ["strategy", "url_template"],
          "properties" => %{
            "strategy" => %{
              "enum" => ["oauth"]
            },
            "url_template" => %{
              "type" => "string",
              "minLength": 6
            }
          },
        },

        %{
          "type" => "object",
          "additionalProperties" => false,
          "requiredProperties" => ["strategy", "third_party_resolver", "secret", "algorithm"],
          "properties" => %{
            "strategy" => %{
              "enum" => ["jwt"]
            },
            "third_party_resolver" => %{
              "type" => "boolean",
              "enum" => [false]
            },
            "secret" => %{
              "type" => "string",
              "minLength": 1
            },
            "algorithm" => %{
              "type" => "string",
              "enum" => [
                "HS256", "HS384", "HS512"
              ]
            }
          },
        },

        %{
          "type" => "object",
          "additionalProperties" => false,
          "requiredProperties" => ["strategy", "third_party_resolver", "secret", "algorithm", "url_template"],
          "properties" => %{
            "strategy" => %{
              "enum" => ["jwt"]
            },
            "third_party_resolver" => %{
              "type" => "boolean",
              "enum" => [true]
            },
            "url_template" => %{
              "type" => "string",
              "minLength": 6
            },
            "secret" => %{
              "type" => "string",
              "minLength": 1
            },
            "algorithm" => %{
              "type" => "string",
              "enum" => [
                "HS256", "HS384", "HS512"
              ]
            }
          },
        },
      ]
    }
  end

  defp maybe_validate_signature(%Changeset{} = changeset) do
    with {:ok, %{"secret" => secret}} when is_binary(secret) <- Changeset.fetch_change(changeset, :settings),
         :error <- Base.decode64(secret) do
      Changeset.add_error(changeset, :"settings.secret", "is not Base64 encoded", validation: :cast)
    else
      _ -> changeset
    end
  end
end
