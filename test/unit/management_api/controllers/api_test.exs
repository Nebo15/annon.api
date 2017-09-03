defmodule Annon.ManagementAPI.Controllers.APITest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.Factories.Configuration, as: ConfigurationFactory

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  describe "on index" do
    test "lists all apis", %{conn: conn} do
      assert [] ==
        conn
        |> get(apis_path())
        |> json_response(200)
        |> Map.get("data")

      api1_id = ConfigurationFactory.insert(:api).id
      api2_id = ConfigurationFactory.insert(:api).id

      resp =
        conn
        |> get(apis_path())
        |> json_response(200)
        |> Map.get("data")

      assert [%{"id" => ^api1_id}, %{"id" => ^api2_id}] = resp
    end

    test "limits results", %{conn: conn} do
      apis = ConfigurationFactory.insert_list(10, :api)

      pagination_query = URI.encode_query(%{
        "limit" => 2
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      resp_ids = [Enum.at(resp, 0)["id"], Enum.at(resp, 1)["id"]]

      assert Enum.at(apis, 0).id in resp_ids
      assert Enum.at(apis, 1).id in resp_ids
      assert length(resp) == 2
    end

    test "lists all apis when limit is nil", %{conn: conn} do
      ConfigurationFactory.insert_list(10, :api)

      pagination_query = URI.encode_query(%{
        "limit" => nil
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 10
    end

    test "lists all apis when limit is invalid", %{conn: conn} do
      ConfigurationFactory.insert_list(10, :api)

      pagination_query = URI.encode_query(%{
        "limit" => "not_a_number"
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 10
    end

    test "filters results by status codes", %{conn: conn} do
      _api = ConfigurationFactory.insert(:api, name: "one")
      api2 = ConfigurationFactory.insert(:api, name: "one two")
      api3 = ConfigurationFactory.insert(:api, name: "one two three")

      # Tolerates query with invalid codes
      filter_query = URI.encode_query(%{
        "name" => "unknown"
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert length(resp) == 0

      # Returns single record
      filter_query = URI.encode_query(%{
        "name" => "three"
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == api3.id
      assert length(resp) == 1

      # Returns multiple records
      filter_query = URI.encode_query(%{
        "name" => "two"
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> filter_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == api2.id
      assert Enum.at(resp, 1)["id"] == api3.id
      assert length(resp) == 2
    end

    test "paginates results", %{conn: conn} do
      # Ending Before
      apis = ConfigurationFactory.insert_list(10, :api)

      pagination_query = URI.encode_query(%{
        "limit" => 2,
        "ending_before" => Enum.at(apis, 9).id
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(apis, 7).id
      assert Enum.at(resp, 1)["id"] == Enum.at(apis, 8).id
      assert length(resp) == 2

      # Without Limit
      pagination_query = URI.encode_query(%{
        "ending_before" => Enum.at(apis, 9).id
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(apis, 0).id
      assert Enum.at(resp, 1)["id"] == Enum.at(apis, 1).id
      assert length(resp) == 9

      # Starting After
      pagination_query = URI.encode_query(%{
        "limit" => 2,
        "starting_after" => Enum.at(apis, 5).id
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(apis, 6).id
      assert Enum.at(resp, 1)["id"] == Enum.at(apis, 7).id
      assert length(resp) == 2

      # Without Limit
      pagination_query = URI.encode_query(%{
        "starting_after" => Enum.at(apis, 5).id
      })

      resp =
        conn
        |> get(apis_path() <> "?" <> pagination_query)
        |> json_response(200)
        |> Map.get("data")

      assert Enum.at(resp, 0)["id"] == Enum.at(apis, 6).id
      assert Enum.at(resp, 1)["id"] == Enum.at(apis, 7).id
      assert length(resp) == 4
    end
  end

  describe "on read" do
    test "returns 404 when api does not exist", %{conn: conn} do
      conn
      |> get(api_path(Ecto.UUID.generate()))
      |> json_response(404)
    end

    test "returns api in valid structure", %{conn: conn} do
      api = ConfigurationFactory.insert(:api)

      resp =
        conn
        |> get(api_path(api.id))
        |> json_response(200)
        |> Map.get("data")

      id = api.id
      name = api.name
      inserted_at = DateTime.to_iso8601(api.inserted_at)
      updated_at = DateTime.to_iso8601(api.updated_at)

      assert %{
        "id" => ^id,
        "name" => ^name,
        "inserted_at" => ^inserted_at,
        "updated_at" => ^updated_at,
        "request" => %{
          "host" => _,
          "methods" => ["GET"],
          "path" => "/my_api/",
          "port" => 80,
          "scheme" => "http"
        },
      } = resp
    end
  end

  describe "on create or update" do
    test "creates api when it does not exist", %{conn: conn} do
      id = Ecto.UUID.generate()
      create_attrs = ConfigurationFactory.params_for(:api)

      resp =
        conn
        |> put_json(api_path(id), %{"api" => create_attrs})
        |> json_response(201)
        |> Map.get("data")

      assert resp["id"] == id
      assert resp["name"] == create_attrs.name

      assert ^resp =
        conn
        |> get(api_path(id))
        |> json_response(200)
        |> Map.get("data")
    end

    test "updates api when it is exists", %{conn: conn} do
      api = ConfigurationFactory.insert(:api)
      update_attrs = ConfigurationFactory.params_for(:api, name: "new name")

      resp =
        conn
        |> put_json(api_path(api.id), %{"api" => update_attrs})
        |> json_response(200)
        |> Map.get("data")

      assert api.id == resp["id"]
      assert DateTime.to_iso8601(api.inserted_at) == resp["inserted_at"]
      assert update_attrs.name == resp["name"]
      assert update_attrs.request.host == resp["request"]["host"]
      assert update_attrs.request.port == resp["request"]["port"]
      assert update_attrs.request.methods == resp["request"]["methods"]
      assert update_attrs.request.scheme == resp["request"]["scheme"]

      assert ^resp =
        conn
        |> get(api_path(api.id))
        |> json_response(200)
        |> Map.get("data")
    end

    test "requires request path to start with /", %{conn: conn} do
      id = Ecto.UUID.generate()

      create_attrs =
        ConfigurationFactory.params_for(:api,
          request: ConfigurationFactory.params_for(:api_request, path: "bad_path/")
        )

      errors =
        conn
        |> put_json(api_path(id), %{"api" => create_attrs})
        |> json_response(422)
        |> Map.get("error")

      assert %{"invalid" => [
        %{
          "entry" => "$.request.path",
          "entry_type" => "json_data_property",
          "rules" => [
            %{
              "description" => "API request path should start with `/`.",
              "params" => ["~r/^\\//"],
              "rule" => "format"
            }
          ]
        }
      ]} = errors
    end

    test "with request as a string returns error changeset", %{conn: conn} do
      id = Ecto.UUID.generate()

      invalid_attrs =
        :api
        |> ConfigurationFactory.params_for()
        |> Map.put(:request, Poison.encode!(ConfigurationFactory.params_for(:api_request, path: "bad_path/")))

      errors =
        conn
        |> put_json(api_path(id), %{"api" => invalid_attrs})
        |> json_response(422)
        |> Map.get("error")

      assert %{"invalid" => [
        %{
          "entry" => "$.request",
          "entry_type" => "json_data_property",
          "rules" => [
            %{
              "description" => "is invalid",
              "params" => ["map"],
              "rule" => "cast"
            }
          ]
        }
      ]} = errors
    end

    test "requires all fields to be present on update", %{conn: conn} do
      api = ConfigurationFactory.insert(:api)
      update_attrs = %{}

      conn
      |> put_json(api_path(api.id), %{"api" => update_attrs})
      |> json_response(422)
    end
  end

  describe "on delete" do
    test "returns no content when api does not exist", %{conn: conn} do
      resp =
        conn
        |> delete(api_path(Ecto.UUID.generate()))
        |> response(204)

      assert "" = resp
    end

    test "returns no content when api is deleted", %{conn: conn} do
      api = ConfigurationFactory.insert(:api)

      resp =
        conn
        |> delete(api_path(api.id))
        |> response(204)

      assert "" = resp

      conn
      |> get(api_path(api.id))
      |> json_response(404)
    end
  end
end
