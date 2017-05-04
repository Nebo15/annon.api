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

  describe "create_api/1" do
    test "with valid data creates a api" do
      assert {:ok, %APISchema{} = api} = API.create_api(@create_attrs)

      assert api.name == @create_attrs.name
      assert api.request.host == @create_attrs.request.host
      assert api.request.methods == @create_attrs.request.methods
      assert api.request.path == @create_attrs.request.path
      assert api.request.port == @create_attrs.request.port
      assert api.request.scheme == @create_attrs.request.scheme
    end

    test "with management port binding returns error changeset" do
      management_port =
        :annon_api
        |> Confex.get_map(:management_http)
        |> Keyword.fetch!(:port)

      create_attrs = %{@create_attrs | request: %{@create_attrs.request | port: management_port}}
      expected_error = {:port, {"This port is reserver for Management API", [validation: :exclusion]}}

      assert {:error, %Ecto.Changeset{} = changeset} = API.create_api(create_attrs)
      assert expected_error in changeset_errors(changeset.changes.request)
    end

    test "with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = API.create_api(%{})
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

  test "delete_api/1 deletes the api" do
    api = ConfigurationFactory.insert(:api)
    assert {:ok, %APISchema{}} = API.delete_api(api)
    assert {:error, :not_found} = API.get_api(api.id)
  end
end
