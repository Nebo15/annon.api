defmodule Gateway.Factory do
  use ExMachina.Ecto, repo: Gateway.DB.Configs.Repo

  def api_factory do
    %Gateway.DB.Schemas.API{
      name: "Jane Smith",
      request: %Gateway.DB.Schemas.API.Request{
        scheme: "http",
        host: "localhost",
        port: 3000,
        path: "/omg/lol",
        method: "GET"
      }
    }
  end

  def plugin_factory do
    %Gateway.DB.Schemas.Plugin{
      name: "Jane Smith",
      is_enabled: false,
      settings: %{},
      api: build(:api)
    }
  end
end
