defmodule Gateway.Acceptance.Plug.ValidatorTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @schema %{"type" => "object",
            "properties" => %{
              "foo" => %{ "type" => "number"},
              "bar" => %{ "type" => "string"}
            },
            "required" => ["bar"]
          }

  test "post hook with empty data" do
    request_data = %{host: get_host(:public), path: "/test", port: get_port(:public), scheme: "http", method: ["POST"]}

    data = get_api_model_data()
    |> Map.put(:request, request_data)
    |> Map.put(:plugins, [
      %{name: "validator", is_enabled: true, settings: %{
        "rules" => [
          %{"methods" => ["GET", "POST"], "path" => ".*", "schema" => @schema}
        ]
      }}
    ])

    "apis"
    |> post(Poison.encode!(data), :management)
    |> assert_status(201)

    "test"
    |> get(:public)
    |> assert_status(404)

    "test"
    |> post("{}", :public)
    |> assert_status(422)
  end
end
