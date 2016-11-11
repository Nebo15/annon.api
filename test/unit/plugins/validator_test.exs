defmodule Gateway.Plugins.ValidatorTest do
  @moduledoc false
  use Gateway.UnitCase, async: true
  alias Gateway.DB.Schemas.API, as: APISchema
  alias Gateway.DB.Schemas.Plugin, as: PluginSchema

  test "validator plugin" do
    schema = %{
      "type" => "object",
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

    model = %APISchema{plugins: [
      %PluginSchema{is_enabled: true, name: "validator", settings: %{"rules" => [%{"methods" => ["GET", "PUT"], "path" => ".*", "schema" => Poison.encode!(schema)}]}}
    ]}

    conn = :get
    |> conn("/", Poison.encode!(%{}))

    conn
    |> Map.put(:body_params, %{"foo" =>  "100500", "bar" => "a"})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt

    conn
    |> Map.put(:body_params, %{"foo" =>  100500, "bar" => "a"})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_not_halt

    conn
    |> Map.put(:body_params, %{"foo" =>  100500})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt
  end
end
