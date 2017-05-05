defmodule Annon.Configuration.APITest do
  @moduledoc false
  use Annon.DataCase, async: true
  alias Annon.Configuration.API
  alias Annon.Configuration.Schemas.API, as: APISchema
  alias Annon.ConfigurationFactory
  alias Ecto.Paging
  alias Ecto.Paging.Cursors

  @create_attrs %{
    name: "An API",
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

      assert {[^api1, ^api2, ^api3], _paging} = API.list_apis(%{"name" => nil})
      assert {[], _paging} = API.list_apis(%{"name" => "unknown"})
      assert {[^api2], _paging} = API.list_apis(%{"name" => "two"})
      assert {[^api1, ^api2], _paging} = API.list_apis(%{"name" => "one"})
    end

    test "paginates results" do
      api1 = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate())
      api2 = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate())
      api3 = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate())
      api4 = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate())
      api5 = ConfigurationFactory.insert(:api, id: Ecto.UUID.generate())

      assert {[^api1, ^api2, ^api3, ^api4, ^api5], _paging} =
        API.list_apis(%{}, %Paging{limit: nil})
      assert {[^api1], _paging} =
        API.list_apis(%{}, %Paging{limit: 1})
      assert {[^api1, ^api2], _paging} =
        API.list_apis(%{}, %Paging{limit: 2})

      assert {[^api2, ^api3], _paging} =
        API.list_apis(%{}, %Paging{limit: 2, cursors: %Cursors{starting_after: api1.id}})
      # TODO: https://github.com/Nebo15/ecto_paging/issues/14
      # assert {[^api3, ^api4], _paging} =
      #   API.list_apis(%{}, %Paging{limit: 2, cursors: %Cursors{ending_before: api5.id}})
    end

    # TODO: https://github.com/Nebo15/ecto_paging/issues/14
    @tag :pending
    test "paginates with filters" do
      api1 = ConfigurationFactory.insert(:api, name: "one")
      api2 = ConfigurationFactory.insert(:api, name: "one two")
      api3 = ConfigurationFactory.insert(:api, name: "one three")
      api4 = ConfigurationFactory.insert(:api, name: "one four")

      assert {[^api2, ^api3], _paging} =
        API.list_apis(
          %{"name" => "one"},
          %Paging{limit: 2, cursors: %Cursors{starting_after: api1.id}}
        )

      assert {[^api2, ^api3], _paging} =
        API.list_apis(
          %{"name" => "my_api_1"},
          %Paging{limit: 2, cursors: %Cursors{ending_before: api4.id}}
        )
    end
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
      assert api.request.host == @create_attrs.request.host
      assert api.request.methods == @create_attrs.request.methods
      assert api.request.path == @create_attrs.request.path
      assert api.request.port == @create_attrs.request.port
      assert api.request.scheme == @create_attrs.request.scheme
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

      plugin = ConfigurationFactory.insert(:proxy_plugin, api_id: api.id)
      assert [%APISchema{
        id: ^api_id,
        plugins: plugins
      }] = API.dump_apis()

      assert length(plugins) == 1
      assert List.first(plugins).id == plugin.id
      assert List.first(plugins).is_enabled == true
    end

    test "filters APIs when plugin is disabled" do
      api = ConfigurationFactory.insert(:api)
      ConfigurationFactory.insert(:proxy_plugin, api_id: api.id, is_enabled: false)
      assert [] == API.dump_apis()

      api_id = api.id

      plugin2 = ConfigurationFactory.insert(:jwt_plugin, api_id: api.id, is_enabled: true)
      assert [%APISchema{
        id: ^api_id,
        plugins: plugins
      }] = API.dump_apis()

      assert length(plugins) == 1
      assert List.first(plugins).id == plugin2.id
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
      assert List.first(plugins1).id == plugin1.id
      assert List.first(plugins1).is_enabled == true

      assert length(plugins2) == 1
      assert List.first(plugins2).id == plugin2.id
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

      assert {:ok, %APISchema{
        id: api_id,
        plugins: plugins
      }} = API.find_api("http", "POST", "example.com", 80, "/my_path")

      assert api_id == api.id
      assert length(plugins) == 1

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
  end

  test "delete_api/1 deletes the api" do
    api = ConfigurationFactory.insert(:api)
    assert {:ok, %APISchema{}} = API.delete_api(api)
    assert {:error, :not_found} = API.get_api(api.id)
  end
end
