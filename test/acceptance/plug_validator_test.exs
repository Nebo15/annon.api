defmodule Gateway.PlugValidatorAcceptanceTest do
  use Gateway.AcceptanceCase, async: true
  alias Gateway.DB.Models.API, as: APIModel

  @api_url "apis"
  @schema %{"type" => "object",
            "properties" => %{
              "foo" => %{ "type" => "number"},
              "bar" => %{ "type" => "string"}
            },
            "required" => ["bar"]
          }

  test "post hook with empty data" do
    data = get_api_model_data()
    |> Map.put(:request, %{host: "localhost", path: "/test", port: 4000, scheme: "http", method: "POST"})
    |> Map.put(:plugins, [%{name: "Validator", settings: %{"schema" => Poison.encode!(@schema)}}])

    '/apis'
    |> post(Poison.encode!(data))

    "test"
    |> get()
    |> assert_status(404)

    "test"
    |> post(Poison.encode!(%{}))
    |> assert_status(422)
  end

end
