defmodule Gateway.Plugins.ValidatorTest do
  use Gateway.UnitCase

  test "validator correct" do
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

    model = %APIModel{plugins: [
      %Plugin{is_enabled: true, name: :Validator, settings: %{"schema" => Poison.encode!(schema)}}
    ]}

    connect = :get
    |> conn("/", Poison.encode!(%{}))

    connect
    |> Map.put(:body_params, %{"foo" =>  "100500", "bar" => "a"})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt

    connect
    |> Map.put(:body_params, %{"foo" =>  100500, "bar" => "a"})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_not_halt

    connect
    |> Map.put(:body_params, %{"foo" =>  100500})
    |> put_private(:api_config, model)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt
  end

end
