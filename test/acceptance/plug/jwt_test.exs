defmodule Gateway.Acceptance.Plug.JWTTest do
  use Gateway.AcceptanceCase, async: true

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
  @consumer_id UUID.uuid1()
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
    |> Map.put(:request, %{host: "localhost", path: "/jwt/test", port: get_port(), scheme: "http", method: "POST"})
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: true, settings: %{"signature" => "secret"}},
      %{name: "Validator", is_enabled: false, settings: %{"schema" => Poison.encode!(@schema)}}
    ])

    @api_url
    |> post(Poison.encode!(data))
    |> assert_status(201)

    @consumer_url
    |> post(Poison.encode!(@consumer))
    |> assert_status(201)

    url = @consumer_url <> "/#{@consumer_id}/plugins"
    url
    |> post(Poison.encode!(@consumer_plugin))
    |> assert_status(201)

    token = jwt_token(@payload, "secret")

    "jwt/test"
    |> post!(Poison.encode!(%{bar: "string"}), [{"authorization", "Bearer invalid.credentials.signature"}])
    |> assert_status(401)

    "jwt/test"
    |> post!(Poison.encode!(%{bar: "string"}), [{"authorization", "Bearer #{token}"}])
    |> assert_status(422)

    "jwt/test"
    |> post!(Poison.encode!(%{foo: "string", bar: 123}), [{"authorization", "Bearer #{token}"}])
    |> assert_status(404)
  end
end
