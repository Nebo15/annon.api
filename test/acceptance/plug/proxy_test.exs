defmodule Gateway.Acceptance.Plug.ProxyTest do
  use Gateway.AcceptanceCase
  alias Gateway.Test.Helper

  @api_url "apis"

  @consumer_id Helper.random_string(32)

  @consumer %{
    external_id: @consumer_id,
    metadata: %{"key": "value"},
  }

  @payload %{"id" => @consumer_id, "name" => "John Doe"}
  @token_secret "proxy_secret"

  test "proxy plugin" do

    api_id = @api_url
    |> post(Poison.encode!(get_api_proxy_data("/proxy/test")), :private)
    |> assert_status(201)
    |> get_body()
    |> Poison.decode!
    |> get_in(["data", "id"])

    proxy_plugin = %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        host: get_host(:private),
        path: "/apis/#{api_id}",
        port: get_port(:private),
        scheme: "http"
      }
    }

    url = @api_url <> "/#{api_id}/plugins"
    url
    |> post(Poison.encode!(proxy_plugin), :private)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    response = "proxy/test"
    |> get(:public, [{"authorization", "Bearer #{jwt_token(@payload, @token_secret)}"}])
    |> assert_status(200)
    |> get_body()
    |> Poison.decode!
    |> Map.get("data")

    assert response["id"] == 1
    assert response["request"]["host"] == get_host(:public)
    assert response["request"]["path"] == "/proxy/test"
    assert response["request"]["port"] == get_port(:public)

  end

  test "proxy without sheme and path" do
    proxy_plugin = %{ name: "proxy", is_enabled: true, settings: %{host: get_host(:private), port: get_port(:private)}}

    "/apis"
    |> get_api_proxy_data()
    |> Map.put(:plugins, [proxy_plugin])
    |> http_api_create()

    Gateway.AutoClustering.do_reload_config()

    "apis"
    |> get(:public, [{"authorization", "Bearer #{jwt_token(@payload, @token_secret)}"}])
    |> assert_status(200)
  end

  test "proxy with additional headers" do
    api_id = @api_url
    |> post(Poison.encode!(get_api_proxy_data("/proxy/test_headers", false)), :private)
    |> assert_status(201)
    |> get_body()
    |> Poison.decode!
    |> get_in(["data", "id"])

    Gateway.AutoClustering.do_reload_config()

    @api_url
    |> post(Poison.encode!(get_api_proxy_data("/proxy/test")), :private)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    proxy_plugin = %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        host: get_host(:public),
        path: "/proxy/test",
        port: get_port(:public),
        scheme: "http"
      }
    }

    url = @api_url <> "/#{api_id}/plugins"
    url
    |> post(Poison.encode!(proxy_plugin), :private)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    "proxy/test_headers"
    |> get(:public)
    |> assert_status(401)

    new_settings = Map.put(proxy_plugin.settings, "additional_headers",
      [%{"authorization" => "Bearer #{jwt_token(@payload, @token_secret)}"}])
    proxy_plugin = Map.put(proxy_plugin, :settings, new_settings)

    url = @api_url <> "/#{api_id}/plugins/proxy"
    url
    |> delete(:private)
    |> assert_status(200)

    url = @api_url <> "/#{api_id}/plugins"
    url
    |> post(Poison.encode!(proxy_plugin), :private)
    |> assert_status(201)

    "proxy/test_headers"
    |> get(:public)
    |> assert_status(404)
  end

  def get_api_proxy_data(path, enable_jwt \\ true) do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: "GET"})
    |> Map.put(:plugins, [
      %{name: "jwt", is_enabled: enable_jwt, settings: %{"signature" => @token_secret}}])
  end
end
