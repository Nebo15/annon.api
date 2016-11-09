defmodule Gateway.Acceptance.Plug.ValidatorTest do
  use Gateway.AcceptanceCase

  @schema %{"type" => "object",
            "properties" => %{
              "foo" => %{ "type" => "number"},
              "bar" => %{ "type" => "string"}
            },
            "required" => ["bar"]
          }

  test "post hook with empty data" do
    api = Gateway.Factory.insert(:api, request: %{
      path: "/test",
      host: get_host(:public),
      port: get_port(:public),
      scheme: "http",
      method: "POST"
    })
    Gateway.Factory.insert(:validator_plugin, api: api, settings: %{"schema" => Poison.encode!(@schema)})

<<<<<<< HEAD
=======
    Gateway.AutoClustering.do_reload_config()

>>>>>>> Moving on
    "test"
    |> get(:public)
    |> assert_status(404)

    "test"
    |> post("{}", :public)
    |> assert_status(422)
  end
end
