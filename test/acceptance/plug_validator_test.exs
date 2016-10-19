defmodule Gateway.Acceptance.PlugValidatorTest do
  use Gateway.AcceptanceCase, async: true

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
    |> Map.put(:request, %{host: "localhost", path: "/test", port: get_port(), scheme: "http", method: "POST"})
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: false, settings: %{"signature" => "secret"}},
      %{name: "Validator", is_enabled: true, settings: %{"schema" => Poison.encode!(@schema)}}
    ])

    "apis"
    |> post(Poison.encode!(data))

    "test"
    |> get()
    |> assert_status(404)

    "test"
    |> post!("{}")
    |> assert_status(422)
  end

end
