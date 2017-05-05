defmodule Annon.Configuration.CacheAdapter.DatabaseTest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Configuration.CacheAdapters.Database
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Annon.ConfigurationFactory

  test "init/0 returns ok" do
    assert :ok == Database.init()
  end

  test "config_change/0 returns ok" do
    assert :ok == Database.config_change()
  end

  test "match_request/5 returns matched apis" do
    api = ConfigurationFactory.insert(:api, request: ConfigurationFactory.build(:api_request, %{
      scheme: "http",
      methods: ["POST"],
      host: "example.com",
      port: 80,
      path: "/my_path"
    }))
    ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

    assert {:ok, %APISchema{
      id: api_id,
      plugins: plugins
    }} = Database.match_request("http", "POST", "example.com", 80, "/my_path")

    assert api_id == api.id
    assert length(plugins) == 1

    assert {:error, :not_found} = Database.match_request("https", "POST", "example.com", 80, "/my_path")
    assert {:error, :not_found} = Database.match_request("http", "POST", "example.com", 8080, "/my_path")
    assert {:error, :not_found} = Database.match_request("http", "GET", "example.com", 80, "/my_path")
    assert {:error, :not_found} = Database.match_request("http", "POST", "other_example.com", 80, "/my_path")
  end
end
