defmodule Gateway.Plugins.ValidatorTest do
  @moduledoc false
  use Gateway.UnitCase, async: true

  test "validator plugin" do
    schema = %{
      "type" => "object",
      "additionalProperties" => false,
      "properties" => %{
        "foo" => %{
          "type" => "number"
        },
        "bar" => %{
          "type" => "string"
        }
      },
      "required" => ["bar"]
    }

    model = Gateway.Factory.build(:api, %{
      plugins: [
        Gateway.Factory.build(:validator_plugin, %{
          settings: %{
            "rules" => [%{"methods" => ["POST"], "path" => ".*", "schema" => schema}]
          }
        })
      ]
    })

    conn = :post
    |> conn("/", Poison.encode!(%{}))

    conn
    |> Map.put(:body_params, %{"foo" =>  "100500", "bar" => "a"})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call([])
    |> assert_conn_status(422)
    |> assert_halt

    conn
    |> Map.put(:body_params, %{"foo" =>  100500, "bar" => "a"})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call([])
    |> assert_conn_status(nil)
    |> assert_not_halt

    conn
    |> Map.put(:body_params, %{"foo" =>  100500})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call([])
    |> assert_conn_status(422)
    |> assert_halt
  end
end
