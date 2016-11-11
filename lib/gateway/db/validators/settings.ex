defmodule Gateway.Changeset.Validator.Settings do
  @moduledoc """
  This module provides helpers to validate individual plugin settings via JSON Schema that is stored inside methods.
  """
  alias Ecto.Changeset
  import Ecto.Changeset
  import Gateway.Changeset.Validator.JsonSchema

  # TODO: JSON Schema has IP type and internal validator for it
  @ip_pattern "^(?:(?:\\*|25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:\\*|25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"

  # JWT
  def validate_settings(%Changeset{changes: %{name: "jwt", settings: settings}} = ch) do
    {%{}, %{signature: :string}}
    |> cast(settings, [:signature])
    |> validate_required([:signature])
    |> put_changeset_errors(ch)
  end

  # ACL
  def validate_settings(%Changeset{changes: %{name: "acl", settings: settings}} = ch) do
    validate_via_json_schema(ch, :settings, %{
      "type" => "object",
      "required" => ["rules"],
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
                "type" => "string"
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
    })
  end

  # Validator
  def validate_settings(%Changeset{changes: %{name: "validator", settings: settings}} = ch) do
    {%{}, %{schema: :string}}
    |> cast(settings, [:schema])
    |> validate_required([:schema])
    |> validate_json(:schema)
    |> put_changeset_errors(ch)
  end

  # IPRestriction
  def validate_settings(%Changeset{changes: %{name: "ip_restriction"}} = ch) do
    ch
    |> validate_via_json_schema(:settings, %{
       "type" => "object",
       "required" => ["ip_whitelist", "ip_blacklist"],
       "properties" => %{
         "ip_whitelist" => %{
           "type" => "array",
           "items" => %{
            "type" => "string",
            "pattern" => @ip_pattern,
           }
         },
         "ip_blacklist" => %{
           "type" => "array",
           "items" => %{
            "type" => "string",
            "pattern" => @ip_pattern,
           }
         },
       },
     })
  end

  # Proxy
  def validate_settings(%Changeset{changes: %{name: "proxy"}} = ch) do
    ch
    |> validate_via_json_schema(:settings, %{
       "type" => "object",
       "additionalProperties" => false,
       "required" => ["host"],
       "properties" => %{
         "additional_headers" => %{
           "type" => "array",
           "items" => %{
             "type" => "object"
           }
         },
         "scheme" => %{
           "enum" => ["http", "https"]
         },
         "host" => %{
           "type" => "string"
         },
         "port" => %{
           "type" => "integer"
         },
         "path" => %{
           "type" => "string"
         },
         "method" => %{
           "type" => "string",
           "enum" => ["GET", "POST", "PUT", "DELETE", "PATCH"]
         },
       },
     })
  end

  # general
  def validate_settings(ch), do: ch

  # helpers
  defp validate_json(%Changeset{} = ch, field) do
    ch
    |> get_field(field, "")
    |> Poison.decode()
    |> validate_json(ch)
  end
  defp validate_json({:ok, _}, ch), do: ch
  defp validate_json({:error, _}, ch) do
    add_error(ch, :settings, "Validator.settings: field 'schema' is invalid json", [validation: :json, json: []])
  end

  defp put_changeset_errors(%Changeset{valid?: true}, ch), do: ch
  defp put_changeset_errors(%Changeset{valid?: false, errors: errors}, ch) do
    ch
    |> Map.merge(%{errors: errors, valid?: false})
  end
end
