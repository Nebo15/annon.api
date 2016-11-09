defmodule Gateway.SmokeTests.BasicProxy do
  use Gateway.AcceptanceCase

  setup do
    {:ok, api} = Gateway.DB.Schemas.API.create(%{
      name: "An HTTPBin service endpoint",
      request: %{
        method: "GET",
        scheme: "http",
        host: "localhost",
        port: get_port(:public),
        path: "/httpbin",
      }
    })

    Gateway.DB.Schemas.Plugin.create(api.id, %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        "method" => "GET",
        "scheme" => "http",
        "host" => "httpbin.org",
        "port" => 80,
        "path" => "/get"
      }
    })

    Gateway.DB.Schemas.Plugin.create(api.id, %{
      name: "acl",
      is_enabled: true,
      settings: %{
        "scope" => "httpbin:read"
      }
    })

    Gateway.DB.Schemas.Plugin.create(api.id, %{
      name: "jwt",
      is_enabled: true,
      settings: %{
        "signature" => "a_secret_signature"
      }
    })

    Gateway.AutoClustering.do_reload_config()

    :ok
  end

  test "A request with no auth header is forbidden to access upstream" do
    api_endpoint = "#{get_host(:public)}:#{get_port(:public)}"

    response =
      "http://#{api_endpoint}/httpbin?my_param=my_value"
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!

    assert "Your scopes does not allow to access this resource." == response["error"]["message"]
    assert "forbidden" == response["error"]["type"]
    assert 403 == response["meta"]["code"]
  end

  test "A request with incorrect auth header is forbidden to access upstream" do
    api_endpoint = "#{get_host(:public)}:#{get_port(:public)}"

    auth_token = jwt_token(%{"scopes" => ["httpbin:wrong"]}, "a_wrong_secret_signature")

    response =
      "http://#{api_endpoint}/httpbin?my_param=my_value"
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!

    assert "There are no JWT token in request or your token is invalid." == response["error"]["message"]
    assert "access_denied" == response["error"]["type"]
    assert 401 == response["meta"]["code"]
  end

  test "A request with good auth header is allowed to access upstream" do
    api_endpoint = "#{get_host(:public)}:#{get_port(:public)}"

    auth_token = jwt_token(%{"scopes" => ["httpbin:read"]}, "a_secret_signature")

    response =
      "http://#{api_endpoint}/httpbin?my_param=my_value"
      |> HTTPoison.get!([{"authorization", "Bearer #{auth_token}"}])
      |> Map.get(:body)
      |> Poison.decode!

    assert "my_value" == response["args"]["my_param"]
  end
end
