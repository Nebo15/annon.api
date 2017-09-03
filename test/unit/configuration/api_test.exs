defmodule Annon.Configuration.APITest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Configuration.API
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Annon.Configuration.Schemas.Plugin, as: PluginSchema
  alias Annon.Factories.Configuration, as: ConfigurationFactory
  alias Ecto.Paging
  alias Ecto.Paging.Cursors

  @create_attrs %{
    name: "An API",
    description: "My lovely API",
    docs_url: "http://example.com/",
    health: "operational",
    disclose_status: false,
    request: %{
      host: "www.example.com",
      methods: ["GET", "PUT"],
      path: "/my_created_api/",
      port: 80,
      scheme: "https"
    }
  }

  describe "list_apis/1" do
    test "returns all apis" do
      assert {[], _paging} = API.list_apis()
      api = ConfigurationFactory.insert(:api)
      assert {[^api], _paging} = API.list_apis()
    end

    test "filters by name" do
      api1 = ConfigurationFactory.insert(:api, name: "API one")
      api2 = ConfigurationFactory.insert(:api, name: "API one two")
      api3 = ConfigurationFactory.insert(:api, name: "API three")

      assert {[^api1, ^api2, ^api3], _paging} = API.list_apis(%{})
      assert {[^api1, ^api2, ^api3], _paging} = API.list_apis(%{"name" => nil})
      assert {[], _paging} = API.list_apis(%{"name" => "unknown"})
      assert {[^api2], _paging} = API.list_apis(%{"name" => "two"})
      assert {[^api1, ^api2], _paging} = API.list_apis(%{"name" => "one"})
    end

    test "paginates results" do
      api1_id = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate()).id
      api2_id = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate()).id
      api3_id = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate()).id
      api4_id = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate()).id
      api5_id = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate()).id

      {page, _paging} = API.list_apis(%{}, %Paging{limit: nil})
      assert [^api1_id, ^api2_id, ^api3_id, ^api4_id, ^api5_id] = Enum.map(page, &(&1.id))

      {page, _paging} = API.list_apis(%{}, %Paging{limit: 1})
      assert [^api1_id] = Enum.map(page, &(&1.id))

      {page, _paging} = API.list_apis(%{}, %Paging{limit: 2})
      assert [^api1_id, ^api2_id] = Enum.map(page, &(&1.id))

      {page, _paging} = API.list_apis(%{}, %Paging{limit: 2, cursors: %Cursors{starting_after: api1_id}})
      assert [^api2_id, ^api3_id] = Enum.map(page, &(&1.id))

      {page, _paging} = API.list_apis(%{}, %Paging{limit: 2, cursors: %Cursors{ending_before: api5_id}})
      assert [^api3_id, ^api4_id] = Enum.map(page, &(&1.id))
    end

    test "paginates with filters" do
      api1_id = ConfigurationFactory.insert(:api, name: "one").id
      api2_id = ConfigurationFactory.insert(:api, name: "one two").id
      api3_id = ConfigurationFactory.insert(:api, name: "one three").id
      api4_id = ConfigurationFactory.insert(:api, name: "one four").id

      {page, _paging} =
        API.list_apis(
          %{"name" => "one"},
          %Paging{limit: 2, cursors: %Cursors{starting_after: api1_id}}
        )
      assert [^api2_id, ^api3_id] = Enum.map(page, &(&1.id))

      {page, _paging} =
        API.list_apis(
          %{"name" => "one"},
          %Paging{limit: 2, cursors: %Cursors{ending_before: api4_id}}
        )
      assert [^api2_id, ^api3_id] = Enum.map(page, &(&1.id))
    end
  end

  test "list_disclosed_apis/0 returns disclosed apis" do
    assert [] = API.list_disclosed_apis()

    ConfigurationFactory.insert(:api)
    assert [] = API.list_disclosed_apis()

    api = ConfigurationFactory.insert(:api, disclose_status: true)
    disclosed_apis = API.list_disclosed_apis()
    assert length(disclosed_apis) == 1
    disclosed_api = List.first(disclosed_apis)

    # Discloses only info data
    assert disclosed_api.id == api.id
    assert disclosed_api.name == api.name
    assert disclosed_api.description == api.description
    assert disclosed_api.health == api.health
    assert disclosed_api.docs_url == api.docs_url

    # Does not expose critical data
    assert disclosed_api.request == nil
    assert disclosed_api.updated_at == nil
    assert disclosed_api.inserted_at == nil
    assert disclosed_api.disclose_status == false
    assert %Ecto.Association.NotLoaded{} = disclosed_api.plugins

    ConfigurationFactory.insert(:api, disclose_status: true)
    assert length(API.list_disclosed_apis()) == 2
  end

  describe "get_api/1" do
    test "returns the api with given id" do
      api = ConfigurationFactory.insert(:api)
      assert {:ok, %APISchema{} = ^api} = API.get_api(api.id)
    end

    test "with invalid api id returns error" do
      assert {:error, :not_found} = API.get_api(Ecto.UUID.generate())
    end
  end

  describe "create_api/2" do
    test "with valid data creates a api" do
      id = Ecto.UUID.generate()
      assert {:ok, %APISchema{} = api} = API.create_api(id, @create_attrs)

      assert api.id == id
      assert api.name == @create_attrs.name
      assert api.description == @create_attrs.description
      assert api.docs_url == @create_attrs.docs_url
      assert api.health == @create_attrs.health
      assert api.disclose_status == @create_attrs.disclose_status
      assert api.request.host == @create_attrs.request.host
      assert api.request.methods == @create_attrs.request.methods
      assert api.request.path == @create_attrs.request.path
      assert api.request.port == @create_attrs.request.port
      assert api.request.scheme == @create_attrs.request.scheme
    end

    test "with request as a string returns error changeset" do
      id = Ecto.UUID.generate()
      invalid_attrs = Map.put(@create_attrs, :request, Poison.encode!(@create_attrs.request))
      assert {:error, %Ecto.Changeset{errors: errors}} = API.create_api(id, invalid_attrs)
      assert {:request, {"is invalid", [type: :map]}} in errors
    end

    test "with invalid data returns error changeset" do
      id = Ecto.UUID.generate()
      assert {:error, %Ecto.Changeset{}} = API.create_api(id, %{})
    end
  end

  describe "update_api/2" do
    test "updates existing api" do
      old_api = ConfigurationFactory.insert(:api)
      assert {:ok, %APISchema{} = api} = API.update_api(old_api, @create_attrs)

      assert api.id == old_api.id
      assert api.inserted_at == old_api.inserted_at
      assert api.name == @create_attrs.name
      assert api.description == @create_attrs.description
      assert api.docs_url == @create_attrs.docs_url
      assert api.health == @create_attrs.health
      assert api.disclose_status == @create_attrs.disclose_status
      assert api.request.host == @create_attrs.request.host
      assert api.request.methods == @create_attrs.request.methods
      assert api.request.path == @create_attrs.request.path
      assert api.request.port == @create_attrs.request.port
      assert api.request.scheme == @create_attrs.request.scheme

      assert {[^api], _} = API.list_apis()
    end

    test "with invalid data returns error changeset" do
      old_api = ConfigurationFactory.insert(:api)
      assert {:error, %Ecto.Changeset{}} = API.update_api(old_api, %{})
    end
  end

  describe "dump_apis/0" do
    test "returns active APIs" do
      assert [] = API.dump_apis()

      api = ConfigurationFactory.insert(:api)
      assert [] = API.dump_apis()

      api_id = api.id

      plugin1 = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      assert [%APISchema{
        id: ^api_id,
        plugins: plugins
      }] = API.dump_apis()

      assert length(plugins) == 1
      assert List.first(plugins).name == plugin1.name
      assert List.first(plugins).is_enabled == true

      ConfigurationFactory.insert(:auth_plugin_with_jwt, api_id: api.id)
      assert [%APISchema{
        id: ^api_id,
        plugins: plugins
      }] = API.dump_apis()

      assert length(plugins) == 2
    end

    test "filters APIs when plugin is disabled" do
      api = ConfigurationFactory.insert(:api)
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id, is_enabled: false)
      assert [] == API.dump_apis()

      api_id = api.id

      plugin2 = ConfigurationFactory.insert(:auth_plugin_with_jwt, api_id: api.id, is_enabled: true)
      assert [%APISchema{
        id: ^api_id,
        plugins: plugins
      }] = API.dump_apis()

      assert length(plugins) == 1
      assert List.first(plugins).name == plugin2.name
      assert List.first(plugins).is_enabled == true
    end

    test "does not return plugins from other APIs" do
      api1 = ConfigurationFactory.insert(:api)
      plugin1 = ConfigurationFactory.insert(:proxy_plugin, api_id: api1.id)
      api1_id = api1.id

      api2 = ConfigurationFactory.insert(:api)
      plugin2 = ConfigurationFactory.insert(:proxy_plugin, api_id: api2.id)
      api2_id = api2.id

      assert [
        %APISchema{
          id: ^api1_id,
          plugins: plugins1
        },
        %APISchema{
          id: ^api2_id,
          plugins: plugins2
        },
      ] = API.dump_apis()

      assert length(plugins1) == 1
      assert List.first(plugins1).name == plugin1.name
      assert List.first(plugins1).is_enabled == true

      assert length(plugins2) == 1
      assert List.first(plugins2).name == plugin2.name
      assert List.first(plugins2).is_enabled == true
    end
  end

  describe "find_api/5" do
    test "returns error when no APIs are matching request" do
      assert {:error, :not_found} == API.find_api("http", "POST", "example.com", 80, "/my_path")
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
      ConfigurationFactory.insert(:auth_plugin_with_jwt, api_id: api.id)

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path")

      assert api_id == api.id
      assert length(plugins) == 2

      assert {:error, :not_found} = API.find_api("https", "POST", "example.com", 80, "/my_path")
      assert {:error, :not_found} = API.find_api("http", "POST", "example.com", 8080, "/my_path")
      assert {:error, :not_found} = API.find_api("http", "GET", "example.com", 80, "/my_path")
      assert {:error, :not_found} = API.find_api("http", "POST", "other_example.com", 80, "/my_path")
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

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "GET", "example.com", 80, "/my_path")

      assert api_id == api.id
      assert length(plugins) == 1

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path")

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

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "subdomain.example.com", 80, "/my_path")

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

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path/some_substring")

      assert api_id == api.id
      assert length(plugins) == 1
    end

    test "returns matched APIs with wildcard paths" do
      api = ConfigurationFactory.insert(:api, request: ConfigurationFactory.build(:api_request, %{
        scheme: "http",
        methods: ["POST"],
        host: "example.com",
        port: 80,
        path: "/my_path/%/comments"
      }))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path/some_substring/comments")

      assert api_id == api.id
      assert length(plugins) == 1
    end

    test "prioritizes matches" do
      api2 = ConfigurationFactory.insert(:api,
        matching_priority: 1,
        request: ConfigurationFactory.build(:api_request, %{
          scheme: "http",
          methods: ["POST"],
          host: "example.com",
          port: 80,
          path: "/my_path"
        }
      ))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api2.id)

      api1 = ConfigurationFactory.insert(:api,
        matching_priority: 2,
        request: ConfigurationFactory.build(:api_request, %{
          scheme: "http",
          methods: ["POST"],
          host: "example.com",
          port: 80,
          path: "/my_path/_%"
        }
      ))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api1.id)

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path/")

      assert api_id == api2.id
      assert length(plugins) == 1

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path/random_id")

      assert api_id == api1.id
      assert length(plugins) == 1
    end

    test "ignores methods when matches are prioritized" do
      api2 = ConfigurationFactory.insert(:api,
        matching_priority: 1,
        request: ConfigurationFactory.build(:api_request, %{
          scheme: "http",
          methods: ["POST"],
          host: "example.com",
          port: 80,
          path: "/my_path"
        }
      ))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api2.id)

      api1 = ConfigurationFactory.insert(:api,
        matching_priority: 2,
        request: ConfigurationFactory.build(:api_request, %{
          scheme: "http",
          methods: ["GET"],
          host: "example.com",
          port: 80,
          path: "/my_path/_%"
        }
      ))
      ConfigurationFactory.insert(:proxy_plugin, api_id: api1.id)

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path/")

      assert api_id == api2.id
      assert length(plugins) == 1

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path/random_id")

      assert api_id == api2.id
      assert length(plugins) == 1
    end
  end

  describe "delete_api/1" do
    test "deletes the api" do
      api = ConfigurationFactory.insert(:api)
      assert {:ok, %APISchema{}} = API.delete_api(api)
      assert {:error, :not_found} = API.get_api(api.id)
    end

    test "deletes associated plugins" do
      api = ConfigurationFactory.insert(:api)
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      ConfigurationFactory.insert(:auth_plugin_with_jwt, api_id: api.id)

      assert {:ok, %APISchema{}} = API.delete_api(api)
      assert {:error, :not_found} = API.get_api(api.id)
      assert [] == ConfigurationRepo.all(PluginSchema)
    end

    test "does not affect other APIs" do
      api1 = ConfigurationFactory.insert(:api)
      ConfigurationFactory.insert(:proxy_plugin, api_id: api1.id)
      ConfigurationFactory.insert(:auth_plugin_with_jwt, api_id: api1.id)

      api2 = ConfigurationFactory.insert(:api)
      ConfigurationFactory.insert(:proxy_plugin, api_id: api2.id)
      ConfigurationFactory.insert(:auth_plugin_with_jwt, api_id: api2.id)

      assert {:ok, %APISchema{}} = API.delete_api(api1)
      assert {:error, :not_found} = API.get_api(api1.id)
      assert {:ok, %APISchema{}} = API.get_api(api2.id)

      persisted_plugins = ConfigurationRepo.all(PluginSchema)
      assert Enum.all?(persisted_plugins, &(&1.api_id == api2.id))
      assert 2 == length(persisted_plugins)
    end
  end
end
