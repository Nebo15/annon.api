defmodule Gateway.Acceptance.Plugin.ValidatorTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @schema %{"type" => "object",
            "properties" => %{"foo" => %{"type" => "number"}, "bar" => %{ "type" => "string"}},
            "required" => ["bar"]}

  setup do
    api_path = "/my_validated_api"
    api = :api
    |> build_factory_params(%{
      request: %{
        method: ["GET", "POST", "PUT", "DELETE"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    %{api_id: api_id, api_path: api_path}
  end

  test "validates versus schema", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      rules: [%{methods: ["GET", "POST", "PUT", "DELETE"], path: ".*", schema: @schema}]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config

    assert %{
      "error" => %{"type" => "validation_failed"}
    } = api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(422)
    |> get_body()

    api_path
    |> put_public_url()
    |> post!(%{bar: "foo"})
    |> assert_status(404)
  end

  # test "multiple rules can be applied", %{api_id: api_id, api_path: api_path} do
  #   acl_plugin = :acl_plugin
  #   |> build_factory_params(%{settings: %{
  #     rules: [
  #       %{methods: ["GET", "POST"], path: "^.*", scopes: ["super_scope"]},
  #       %{methods: ["GET"], path: "^.*", scopes: ["api:access", "api:request"]},
  #     ]
  #   }})

  #   "apis/#{api_id}/plugins"
  #   |> put_management_url()
  #   |> post!(acl_plugin)
  #   |> assert_status(201)

  #   Gateway.AutoClustering.do_reload_config()

  #   token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
  #   headers = [{"authorization", "Bearer #{token}"}]

  #   api_path
  #   |> put_public_url()
  #   |> get!(headers)
  #   |> assert_status(404)
  # end

  # describe "rules is filtered" do
  #   test "by method", %{api_id: api_id, api_path: api_path} do
  #     acl_plugin = :acl_plugin
  #     |> build_factory_params(%{settings: %{
  #       rules: [
  #         %{methods: ["GET", "POST"], path: "^.*", scopes: ["super_scope"]},
  #         %{methods: ["PUT"], path: "^.*", scopes: ["api:access", "api:request"]},
  #       ]
  #     }})

  #     "apis/#{api_id}/plugins"
  #     |> put_management_url()
  #     |> post!(acl_plugin)
  #     |> assert_status(201)

  #     Gateway.AutoClustering.do_reload_config()

  #     token = build_jwt_token(%{"scopes" => ["api:access", "api:request"]}, @jwt_secret)
  #     headers = [{"authorization", "Bearer #{token}"}]

  #     api_path
  #     |> put_public_url()
  #     |> get!(headers)
  #     |> assert_status(403)
  #   end

  #   test "by path", %{api_id: api_id, api_path: api_path} do
  #     acl_plugin = :acl_plugin
  #     |> build_factory_params(%{settings: %{
  #       rules: [
  #         %{methods: ["GET"], path: "^/foo$", scopes: ["super_scope"]},
  #       ]
  #     }})

  #     "apis/#{api_id}/plugins"
  #     |> put_management_url()
  #     |> post!(acl_plugin)
  #     |> assert_status(201)

  #     Gateway.AutoClustering.do_reload_config()

  #     token = build_jwt_token(%{"scopes" => ["super_scope"]}, @jwt_secret)
  #     headers = [{"authorization", "Bearer #{token}"}]

  #     "#{api_path}/foo"
  #     |> put_public_url()
  #     |> get!(headers)
  #     |> assert_status(404)
  #   end
  # end
end
