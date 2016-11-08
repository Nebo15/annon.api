defmodule Gateway.Factory do
  use ExMachina.Ecto, repo: Gateway.DB.Configs.Repo

  # APIs

  def api_factory do
    %Gateway.DB.Schemas.API{
      name: sequence(:api_name, &"An API ##{&1}"),
      request: build(:request)
    }
  end

  def api_with_default_plugins_factory do
    %Gateway.DB.Schemas.API{
      name: sequence(:api_name, &"An API ##{&1}"),
      request: build(:request),
      plugins: [
        build(:jwt_plugin),
        build(:acl_plugin)
      ]
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

  def plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "Jane Smith",
      is_enabled: true,
      settings: %{},
      api: build(:api)
    }
  end

  def proxy_plugin_factory do
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
end
