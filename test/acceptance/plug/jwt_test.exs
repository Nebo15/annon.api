defmodule Gateway.Acceptance.Plug.JWTTest do
  use Gateway.AcceptanceCase

  @api_url "apis"
  @consumer_url "consumers"

  @schema %{"type" => "object",
            "properties" => %{
              "foo" => %{ "type" => "number"},
              "bar" => %{ "type" => "string"}
            },
            "required" => ["bar"]
          }

  @consumer_schema %{"type" => "object",
                     "properties" => %{
                       "foo" => %{ "type" => "string"},
                       "bar" => %{ "type" => "number"}
                     },
                     "required" => ["foo"]
                   }
  @consumer_id random_string(32)
  @consumer %{
    external_id: @consumer_id,
    metadata: %{"key": "value"},
  }
  @consumer_plugin %{
    plugin_id: 2, # holy hardcoded shit
    is_enabled: true,
    settings: %{"schema" => Poison.encode!(@consumer_schema)}
  }
  @payload %{"id" => @consumer_id, "name" => "John Doe"}

  test "jwt consumer plugins settings rewrite" do

    data = get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: "/jwt/test", port: get_port(:public), scheme: "http", method: "POST"})
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: true, settings: %{"signature" => "jwt_test_secret"}},
      %{name: "Validator", is_enabled: false, settings: %{"schema" => Poison.encode!(@schema)}}
    ])

    @api_url
    |> post(Poison.encode!(data), :private)
    |> assert_status(201)

    @consumer_url
    |> post(Poison.encode!(@consumer), :private)
    |> assert_status(201)

    url = @consumer_url <> "/#{@consumer_id}/plugins"
    url
    |> post(Poison.encode!(@consumer_plugin), :private)
    |> assert_status(201)

    token = jwt_token(@payload, "jwt_test_secret")

    "jwt/test"
    |> post(Poison.encode!(%{bar: "string"}), :public, [{"authorization", "Bearer invalid.credentials.signature"}])
    |> assert_status(401)

    "jwt/test"
    |> post(Poison.encode!(%{bar: "string"}), :public, [{"authorization", "Bearer #{token}"}])
    |> assert_status(422)

    "jwt/test"
    |> post(Poison.encode!(%{foo: "string", bar: 123}), :public, [{"authorization", "Bearer #{token}"}])
    |> assert_status(404)
  end

  test "jwt default plugins settings" do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: "/jwt/default", port: get_port(:public), scheme: "http", method: "GET"})
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: true, settings: %{"signature" => "jwt_default_secret"}},
    ])
    |> http_api_create()

    "jwt/default"
    |> get(:public, [{"authorization", "Bearer invalid.credentials.signature"}])
    |> assert_status(401)

    "jwt/default"
    |> get(:public, [{"authorization", "Bearer #{jwt_token(@payload, "jwt_default_secret")}"}])
    |> assert_status(404)
  end
end
