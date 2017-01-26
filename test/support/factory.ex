defmodule Gateway.Factory do
  @moduledoc """
  This module lists factories, a mean suitable
  for tests that involve preparation of DB data
  """

  use ExMachina.Ecto, repo: Gateway.DB.Configs.Repo

  # APIs

  def api_factory do
    %Gateway.DB.Schemas.API{
      name: sequence(:api_name, &"An API ##{&1}"),
      request: build(:request)
    }
  end

  def request_factory do
    %Gateway.DB.Schemas.API.Request{
      methods: ["GET"],
      scheme: "http",
      host: sequence(:host, &"www.example#{&1}.com"),
      port: 80,
      path: "/my_api/"
    }
  end

  # Plugin

  def proxy_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "proxy",
      is_enabled: true,
      settings: %{}
    }
  end

  def scopes_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "scopes",
      is_enabled: true,
      settings: %{}
    }
  end

  def jwt_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "jwt",
      is_enabled: true,
      settings: %{"signature" => Gateway.AcceptanceCase.build_jwt_signature("secret-sign")}
    }
  end

  def acl_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "acl",
      is_enabled: true,
      settings: %{
        "rules" => [
          %{"methods" => ["GET"], "path" => ".*", "scopes" => ["some_resource:read"]}
        ]
      }
    }
  end

  def cors_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "cors",
      is_enabled: true,
      settings: %{
        "origin" => ["*"]
      }
    }
  end

  def idempotency_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "idempotency",
      is_enabled: true,
      settings: %{}
    }
  end

  def ip_restriction_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "ip_restriction",
      is_enabled: true,
      settings: %{}
    }
  end

  def ua_restriction_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "ua_restriction",
      is_enabled: true,
      settings: %{}
    }
  end

  def validator_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "validator",
      is_enabled: true,
      settings: %{}
    }
  end
end
