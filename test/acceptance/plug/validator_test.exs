defmodule Gateway.Acceptance.Plug.ValidatorTest do
  use Gateway.AcceptanceCase

  @api_url "apis"
  @schema %{"type" => "object",
            "properties" => %{
              "foo" => %{ "type" => "number"},
              "bar" => %{ "type" => "string"}
            },
            "required" => ["bar"]
          }

  test "post hook with empty data" do
    request_data = %{host: get_host(:public), path: "/test", port: get_port(:public), scheme: "http", method: "POST"}

    data = get_api_model_data()
    |> Map.put(:request, request_data)
    |> Map.put(:plugins, [
      %{name: "jwt", is_enabled: false, settings: %{"signature" => "secret"}},
      %{name: "validator", is_enabled: true, settings: %{"schema" => Poison.encode!(@schema)}}
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(201)

    "test"
    |> get(:public)
    |> assert_status(404)

    "test"
    |> post("{}", :public)
    |> assert_status(422)
  end

end
