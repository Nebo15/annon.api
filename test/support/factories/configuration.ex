defmodule Annon.Factories.Configuration do
  @moduledoc """
  This module lists Configuration-related factories, a mean suitable
  for tests that involve preparation of DB data.
  """
  use ExMachina.Ecto, repo: Annon.Configuration.Repo

  # APIs

  def api_factory do
    %Annon.Configuration.Schemas.API{
      id: Ecto.UUID.generate(),
      name: sequence(:api_name, &"An API ##{&1}"),
      description: sequence(:api_description, &"An API description ##{&1}"),
      health: "operational",
      docs_url: sequence(:api_docs_url, &"example.com/#{&1}"),
      disclose_status: false,
      request: build(:api_request)
    }
  end

  def api_request_factory do
    %Annon.Configuration.Schemas.API.Request{
      methods: ["GET"],
      scheme: "http",
      host: sequence(:host, &"www.example#{&1}.com"),
      port: 80,
      path: "/my_api/"
    }
  end

  # Plugins

  def proxy_plugin_factory do
    %Annon.Configuration.Schemas.Plugin{
      name: "proxy",
      is_enabled: true,
      settings: %{
        "upstream" => build(:proxy_plugin_upstream)
      }
    }
  end

  def proxy_plugin_upstream_factory do
    %{
      "host" => sequence(:host, &"www.example#{&1}.com"),
      "port" => 80
    }
  end

  def auth_plugin_with_oauth_factory do
    mock_conf = Confex.get_env(:annon_api, :acceptance)[:mock]
    mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/"

    %Annon.Configuration.Schemas.Plugin{
      name: "auth",
      is_enabled: true,
      settings: %{
        "strategy" => "oauth",
        "url_template" => "#{mock_url}/oauth/tokens/{access_token}"
      }
    }
  end

  def auth_plugin_with_jwt_factory do
    %Annon.Configuration.Schemas.Plugin{
      name: "auth",
      is_enabled: true,
      settings: %{
        "strategy" => "jwt",
        "secret" => Base.encode64("a_secret_signature"),
        "third_party_resolver" => false,
        "algorithm" => "HS256"
      }
    }
  end

  def acl_plugin_factory do
    %Annon.Configuration.Schemas.Plugin{
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
    %Annon.Configuration.Schemas.Plugin{
      name: "cors",
      is_enabled: true,
      settings: %{
        "origin" => ["*"]
      }
    }
  end

  def idempotency_plugin_factory do
    %Annon.Configuration.Schemas.Plugin{
      name: "idempotency",
      is_enabled: true,
      settings: %{}
    }
  end

  def ip_restriction_plugin_factory do
    %Annon.Configuration.Schemas.Plugin{
      name: "ip_restriction",
      is_enabled: true,
      settings: %{}
    }
  end

  def ua_restriction_plugin_factory do
    %Annon.Configuration.Schemas.Plugin{
      name: "ua_restriction",
      is_enabled: true,
      settings: %{}
    }
  end

  def validator_plugin_factory do
    %Annon.Configuration.Schemas.Plugin{
      name: "validator",
      is_enabled: true,
      settings: %{}
    }
  end
end
