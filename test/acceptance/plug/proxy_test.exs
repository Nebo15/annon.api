defmodule Gateway.Acceptance.Plug.ProxyTest do
  use Gateway.AcceptanceCase

  @api_url "apis"

  @consumer_id UUID.uuid1()

  @consumer %{
    external_id: @consumer_id,
    metadata: %{"key": "value"},
  }

  @payload %{"id" => @consumer_id, "name" => "John Doe"}

  test "proxy plugin" do

    data = get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: "/proxy/test", port: get_port(:public), scheme: "http", method: "GET"})
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: true, settings: %{"signature" => "jwt_test_secret"}}])

    api_id = @api_url
    |> post(Poison.encode!(data), :private)
    |> assert_status(201)
    |> get_body()
    |> Poison.decode!
    |> Map.get("data")
    |> Map.get("id")

    proxy_plugin = %{ name: "Proxy", is_enabled: true,
                      settings: %{
                        "proxy_to" => Poison.encode!(%{
                          host: get_host(:private),
                          path: "/apis/#{api_id}",
                          port: get_port(:private),
                          scheme: "http"
                          })
                      }
                    }

    url = @api_url <> "/#{api_id}/plugins"
    url
    |> post(Poison.encode!(proxy_plugin), :private)
    |> assert_status(201)

    response = "proxy/test"
    |> get(:public, [{"authorization", "Bearer #{jwt_token(@payload, "jwt_test_secret")}"}])
    |> assert_status(200)
    |> get_body()
    |> Poison.decode!
    |> Map.get("data")

    assert response["id"] == 1
    assert response["request"]["host"] == get_host(:public)
    assert response["request"]["path"] == "/proxy/test"
    assert response["request"]["port"] == get_port(:public)

  end

end
