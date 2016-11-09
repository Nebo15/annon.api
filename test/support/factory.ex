defmodule Gateway.Factory do
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
      method: "GET",
      scheme: "http",
      host: sequence(:host, &"www.example#{&1}.com"),
      port: 80,
      path: "/apis"
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

  def jwt_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "jwt",
      is_enabled: true,
      settings: %{"signature" => "secret-sign"}
    }
  end

  def acl_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "acl",
      is_enabled: true,
      settings: %{"scope" => "read"}
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

  def validator_plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "validator",
      is_enabled: true,
      settings: %{}
    }
  end

  # Consumers

  def consumer_factory do
    %Gateway.DB.Schemas.Consumer{
      external_id: "18f2de7e-a5c3-11e6-80f5-76304dec7eb7",
      metadata: %{}
    }
  end

  # Consumer plugin settings

  def consumer_plugin_settings_factory do
    %Gateway.DB.Schemas.ConsumerPluginSettings{
      is_enabled: true,
      settings: %{},
      consumer: build(:consumer),
    }
  end
end
