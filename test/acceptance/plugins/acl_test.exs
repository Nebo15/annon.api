defmodule Gateway.Acceptance.Plugin.ACLTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @jwt_secret "secret"

  setup do
    request_data = %{host: get_host(:public), path: "/acl", port: get_port(:public), scheme: "http", method: ["POST"]}
    request_data
    |> api_acl_data("acl_create")
    |> http_api_create()

    request_data
    |> Map.put(:method, ["GET"])
    |> api_acl_data("acl_read")
    |> http_api_create()

    Gateway.AutoClustering.do_reload_config()

    :ok
  end

  test "token without scopes" do
    token_without_scopes = jwt_token(%{"name" => "Alice"}, @jwt_secret)

    "acl"
    |> get(:public, [{"authorization", "Bearer #{token_without_scopes}"}])
    |> assert_status(403)

    "acl"
    |> post("{}", :public, [{"authorization", "Bearer #{token_without_scopes}"}])
    |> assert_status(403)
  end

  test "just write" do
    token_w = jwt_token(%{"scopes" => ["acl_create", "asd"]}, @jwt_secret)
    "acl"
    |> post("{}", :public, [{"authorization", "Bearer #{token_w}"}])
    |> assert_status(404)

    "acl"
    |> get(:public, [{"authorization", "Bearer #{token_w}"}])
    |> assert_status(403)
  end

  test "just read" do
    token_r = jwt_token(%{"scopes" => ["acl_read"]}, @jwt_secret)
    "acl"
    |> post("{}", :public, [{"authorization", "Bearer #{token_r}"}])
    |> assert_status(403)

    "acl"
    |> get(:public, [{"authorization", "Bearer #{token_r}"}])
    |> assert_status(404)
  end

  test "read and write" do
    token_rw = jwt_token(%{"scopes" => ["acl_read", "acl_create"]}, @jwt_secret)
    "acl"
    |> post("{}", :public, [{"authorization", "Bearer #{token_rw}"}])
    |> assert_status(404)

    "acl"
    |> get(:public, [{"authorization", "Bearer #{token_rw}"}])
    |> assert_status(404)
  end

  test "invalid JWT.scopes type" do
    get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "jwt", is_enabled: true, settings: %{"signature" => @jwt_secret}},
      %{name: "acl", is_enabled: true, settings: %{
        "rules" => [
          %{"methods" => ["GET"], "path" => ".*", "scopes" => ["acl_read"]}
        ]
      }}
    ])

    |> Map.put(:request,
      %{host: get_host(:public), path: "/acl/scopes", port: get_port(:public), scheme: "http", method: ["GET"]})
    |> http_api_create()

    Gateway.AutoClustering.do_reload_config()

    token = jwt_token(%{"scopes" => "invalid"}, @jwt_secret)
    "acl/scopes"
    |> get(:public, [{"authorization", "Bearer #{token}"}])
    |> assert_status(501)
  end

  def api_acl_data(request_data, scope) when is_binary(scope) do
    get_api_model_data()
    |> Map.put(:request, request_data)
    |> Map.put(:plugins, [
      %{name: "jwt", is_enabled: true, settings: %{"signature" => @jwt_secret}},
      %{name: "acl", is_enabled: true, settings: %{
        "rules" => [
          %{"methods" => request_data.method, "path" => ".*", "scopes" => [scope]}
        ]
      }}
    ])
  end
end
