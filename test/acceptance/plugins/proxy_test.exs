defmodule Gateway.Acceptance.Plugin.ProxyTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @api_url "apis"

  @consumer_id Ecto.UUID.generate()

  @consumer %{
    external_id: @consumer_id,
    metadata: %{"key": "value"},
  }

  @payload %{"id" => @consumer_id, "name" => "John Doe"}
  @token_secret "proxy_secret"

  test "proxy plugin" do

    api_id = @api_url
    |> post(Poison.encode!(get_api_proxy_data("/proxy/test")), :management)
    |> assert_status(201)
    |> get_body()
    |> Poison.decode!
    |> get_in(["data", "id"])

    proxy_plugin = %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        host: get_host(:management),
        path: "/apis/#{api_id}",
        port: get_port(:management),
        scheme: "http"
      }
    }

    url = @api_url <> "/#{api_id}/plugins"
    url
    |> post(Poison.encode!(proxy_plugin), :management)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    response = "proxy/test"
    |> get(:public, [{"authorization", "Bearer #{jwt_token(@payload, @token_secret)}"}])
    |> assert_status(200)
    |> get_body()
    |> Poison.decode!
    |> Map.get("data")

    assert response["id"] == api_id
    assert response["request"]["host"] == get_host(:public)
    assert response["request"]["path"] == "/proxy/test"
    assert response["request"]["port"] == get_port(:public)

  end

  test "proxy without sheme and path" do
    proxy_plugin = %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        host: get_host(:management),
        port: get_port(:management)
      }
    }

    "/apis"
    |> get_api_proxy_data()
    |> Map.put(:plugins, [proxy_plugin])
    |> http_api_create()

    Gateway.AutoClustering.do_reload_config()

    "apis"
    |> get(:public, [{"authorization", "Bearer #{jwt_token(@payload, @token_secret)}"}])
    |> assert_status(200)
  end

  test "proxy settings scheme validator" do
    @api_url
    |> post(Poison.encode!(get_api_data("/proxy/invalid_scheme", "http", "GET")), :management)
    |> assert_status(201)

    @api_url
    |> post(Poison.encode!(get_api_data("/proxy/invalid_scheme", "httpa", "GET")), :management)
    |> assert_status(422)
  end

  test "proxy settings method validator" do
    @api_url
    |> post(Poison.encode!(get_api_data("/proxy/invalid_scheme", "http", "GET")), :management)
    |> assert_status(201)

    @api_url
    |> post(Poison.encode!(get_api_data("/proxy/invalid_scheme", "https", "GETS")), :management)
    |> assert_status(422)
  end

  test "proxy with additional headers" do
    api_id = @api_url
    |> post(Poison.encode!(get_api_proxy_data("/proxy/test_headers", false)), :management)
    |> assert_status(201)
    |> get_body()
    |> Poison.decode!
    |> get_in(["data", "id"])

    Gateway.AutoClustering.do_reload_config()

    @api_url
    |> post(Poison.encode!(get_api_proxy_data("/proxy/test")), :management)
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
    |> post(Poison.encode!(proxy_plugin), :management)
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
    |> delete(:management)
    |> assert_status(200)

    url = @api_url <> "/#{api_id}/plugins"
    url
    |> post(Poison.encode!(proxy_plugin), :management)
    |> assert_status(201)

    "proxy/test_headers"
    |> get(:public)
    |> assert_status(404)
  end

  def get_api_proxy_data(path, enable_jwt \\ true) do
    :api
    |> build_factory_params()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: ["GET"]})
    |> Map.put(:plugins, [
      %{name: "jwt", is_enabled: enable_jwt, settings: %{"signature" => @token_secret}}])
  end

  def get_api_data(path, sheme, method) do
    path
    |> get_api_proxy_data()
    |> Map.put(:plugins, [
    %{
      name: "proxy",
      is_enabled: true,
      settings: %{
        host: get_host(:public),
        path: path,
        port: get_port(:public),
        method: method,
        scheme: sheme
      }
    }])
  end
end
