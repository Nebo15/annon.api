defmodule Gateway.Factory do
  use ExMachina.Ecto, repo: Gateway.DB.Configs.Repo

  def api_factory do
    %Gateway.DB.Schemas.API{
      name: sequence(:api_name, &"An API ##{&1}"),
      request: build(:request)
    }
  end

  def request_factory() do
    %Gateway.DB.Schemas.API.Request{
      method: "GET",
      scheme: "http",
      host: "www.example.com",
      port: 80,
      path: "/apis"
    }
  end

  def plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "Jane Smith",
      is_enabled: true,
      settings: %{},
      api: build(:api)
    }
  end
end
