defmodule Annon.Configuration.CacheAdapter.ETSTest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Configuration.CacheAdapters.ETS
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Annon.ConfigurationFactory

  @test_table_name :test_configuration

  setup do
    :ok = ETS.init([cache_space: @test_table_name])
  end

  test "config_change/0 returns ok" do
    assert :ok == ETS.config_change([cache_space: @test_table_name])
  end

  describe "match_request/5" do
    test "returns error when no APIs are matching request" do
      assert {:error, :not_found} ==
        ETS.match_request("http", "POST", "example.com", 80, "/my_path", [cache_space: @test_table_name])
    end

    test "returns matched APIs" do
      api = ConfigurationFactory.insert(:api, request: ConfigurationFactory.build(:api_request, %{
        scheme: "http",
        methods: ["POST"],
        host: "example.com",
        port: 80,
        path: "/my_path"
      }))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      :ok = ETS.config_change([cache_space: @test_table_name])

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = ETS.match_request("http", "POST", "example.com", 80, "/my_path", [cache_space: @test_table_name])

      assert api_id == api.id
      assert length(plugins) == 1

      assert {:error, :not_found} =
        ETS.match_request("https", "POST", "example.com", 80, "/my_path", [cache_space: @test_table_name])
      assert {:error, :not_found} =
        ETS.match_request("http", "POST", "example.com", 8080, "/my_path", [cache_space: @test_table_name])
      assert {:error, :not_found} =
        ETS.match_request("http", "GET", "example.com", 80, "/my_path", [cache_space: @test_table_name])
      assert {:error, :not_found} =
        ETS.match_request("http", "POST", "other_example.com", 80, "/my_path", [cache_space: @test_table_name])
    end

    test "returns matched APIs with multiple methods" do
      api = ConfigurationFactory.insert(:api, request: ConfigurationFactory.build(:api_request, %{
        scheme: "http",
        methods: ["POST", "GET"],
        host: "example.com",
        port: 80,
        path: "/my_path"
      }))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      :ok = ETS.config_change([cache_space: @test_table_name])

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = ETS.match_request("http", "GET", "example.com", 80, "/my_path", [cache_space: @test_table_name])

      assert api_id == api.id
      assert length(plugins) == 1

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = ETS.match_request("http", "POST", "example.com", 80, "/my_path", [cache_space: @test_table_name])

      assert api_id == api.id
      assert length(plugins) == 1
    end

    test "returns matched APIs with wildcard domain" do
      api = ConfigurationFactory.insert(:api, request: ConfigurationFactory.build(:api_request, %{
        scheme: "http",
        methods: ["POST"],
        host: "%.example.com",
        port: 80,
        path: "/my_path"
      }))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      :ok = ETS.config_change([cache_space: @test_table_name])

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = ETS.match_request("http", "POST", "subdomain.example.com", 80, "/my_path", [cache_space: @test_table_name])

      assert api_id == api.id
      assert length(plugins) == 1
    end

    test "returns matched APIs with deep paths" do
      api = ConfigurationFactory.insert(:api, request: ConfigurationFactory.build(:api_request, %{
        scheme: "http",
        methods: ["POST"],
        host: "example.com",
        port: 80,
        path: "/my_path"
      }))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      :ok = ETS.config_change([cache_space: @test_table_name])

      opts = [cache_space: @test_table_name]

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = ETS.match_request("http", "POST", "example.com", 80, "/my_path/some_substring", opts)

      assert api_id == api.id
      assert length(plugins) == 1
    end
  end
end
