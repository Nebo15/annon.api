defmodule Gateway.Changeset.Validator.Settings do
  @moduledoc """
  This module provides helpers to validate individual plugin settings via JSON Schema that is stored inside methods.
  """
  alias Ecto.Changeset
  import Ecto.Changeset
  import Gateway.Changeset.Validator.JsonSchema

  # JWT
  def validate_settings(%Changeset{changes: %{name: "jwt", settings: settings}} = ch) do
    {%{}, %{signature: :string}}
    |> cast(settings, [:signature])
    |> validate_required([:signature])
    |> put_changeset_errors(ch)
  end

  # ACL
  def validate_settings(%Changeset{changes: %{name: "acl"}} = ch) do
    validate_via_json_schema(ch, :settings, %{
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
  def validate_settings(%Changeset{changes: %{name: "validator"}} = ch) do
    validate_via_json_schema(ch, :settings, %{
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
                  "enum" => ["GET", "POST", "PUT", "DELETE", "PATCH"]
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

  # IPRestriction
  def validate_settings(%Changeset{changes: %{name: "ip_restriction"}} = ch) do
    ch
    |> validate_via_json_schema(:settings, %{
      "type" => "object",
      "anyOf" => [
        %{"required" => ["ip_whitelist", "ip_blacklist"]},
        %{"required" => ["ip_whitelist"]},
        %{"required" => ["ip_blacklist"]}
      ],
      "additionalProperties" => false,
      "properties" => %{
        "ip_whitelist" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "oneOf": [
              %{"format" => "ipv4"}
            ]
          }
        },
        "ip_blacklist" => %{
          "type" => "array",
          "items" => %{
            "type" => "string",
            "oneOf": [
              %{"format" => "ipv4"}
            ]
          }
        }
      }
    })
  end

  # Proxy
  def validate_settings(%Changeset{changes: %{name: "proxy"}} = ch) do
    ch
    |> validate_via_json_schema(:settings, %{
      "type" => "object",
      "required" => ["host"],
      "additionalProperties" => false,
      "properties" => %{
        "scheme" => %{
          "enum" => ["http", "https"]
        },
        "host" => %{
          "type" => "string",
          "oneOf": [
            %{"format" => "hostname"},
            %{"format" => "ipv4"}
          ]
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
        "strip_request_path" => %{
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

  # general
  def validate_settings(ch), do: ch

  defp put_changeset_errors(%Changeset{valid?: true}, ch), do: ch
  defp put_changeset_errors(%Changeset{valid?: false, errors: errors}, ch) do
    ch
    |> Map.merge(%{errors: errors, valid?: false})
  end
end
