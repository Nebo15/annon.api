defmodule Gateway.Acceptance.Smoke.AclTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  setup do
    api_path = "/httpbin"
    api = :api
    |> build_factory_params(%{
      name: "An HTTPBin service endpoint",
      request: %{
        method: ["GET", "POST"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path,
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    proxy_plugin = :proxy_plugin
    |> build_factory_params(%{settings: %{
      scheme: "http",
      host: "httpbin.org",
      port: 80,
      path: "/get",
      strip_request_path: true
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(proxy_plugin)
    |> assert_status(201)

    acl_plugin = :acl_plugin
    |> build_factory_params(%{settings: %{
      rules: [
        %{methods: ["GET"], path: "^.*", scopes: ["httpbin:read"]},
        %{methods: ["PUT", "POST", "DELETE"], path: "^.*", scopes: ["httpbin:write"]},
      ]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(acl_plugin)
    |> assert_status(201)

    jwt_plugin = :jwt_plugin
    |> build_factory_params(%{settings: %{signature: "a_secret_signature"}})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(jwt_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    %{api_path: api_path}
  end

  test "A request with no auth header is forbidden to access upstream", %{api_path: api_path} do
    response =
      "/httpbin?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!

    assert "You need to use JWT token to access this resource." == response["error"]["message"]
    assert "access_denied" == response["error"]["type"]
    assert 401 == response["meta"]["code"]

    assert_logs_are_written(response)
  end

  test "A request with incorrect auth header is forbidden to access upstream", %{api_path: api_path} do
    response =
      "/httpbin?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.get!([{"authorization", "Bearer bad_token"}])
      |> Map.get(:body)
      |> Poison.decode!

    assert "Your JWT token is invalid." == response["error"]["message"]
    assert "access_denied" == response["error"]["type"]
    assert 401 == response["meta"]["code"]

    assert_logs_are_written(response)
  end

  test "A request with good auth header is allowed to access upstream", %{api_path: api_path} do
    auth_token = build_jwt_token(%{"scopes" => ["httpbin:read"]}, "a_secret_signature")

    response =
      "/httpbin?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.get!([{"authorization", "Bearer #{auth_token}"}])
      |> Map.get(:body)
      |> Poison.decode!

    assert "my_value" == response["args"]["my_param"]

    assert_logs_are_written(response)
  end

  test "A valid access scope is required to access upstream", %{api_path: api_path} do
    auth_token = build_jwt_token(%{"scopes" => ["httpbin:read"]}, "a_secret_signature")
    headers = [
      {"authorization", "Bearer #{auth_token}"},
      {"content-type", "application/json"}
    ]

    response =
      "/httpbin?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.post!(Poison.encode!(%{}), headers)
      |> Map.get(:body)
      |> Poison.decode!

    assert "Your scopes does not allow to access this resource." == response["error"]["message"]
    assert "forbidden" == response["error"]["type"]
    assert 403 == response["meta"]["code"]

    assert_logs_are_written(response)
  end

  defp assert_logs_are_written(response) do
    log_entry = Gateway.DB.Logger.Repo.one(Gateway.DB.Schemas.Log)
    logged_response = Poison.decode!(log_entry.response.body)

    assert logged_response == response
  end
end
