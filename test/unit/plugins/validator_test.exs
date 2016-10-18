defmodule Gateway.Plugins.ValidatorTest do
  use Gateway.HTTPTestHelper

  test "user is redirected when current_user is not assigned" do
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

    connect = :get
    |> conn("/", Poison.encode!(%{}))

    connect
    |> Map.put(:body_params, %{"foo" =>  "100500", "bar" => "a"})
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt

    connect
    |> Map.put(:body_params, %{"foo" =>  100500, "bar" => "a"})
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_not_halt

    connect
    |> Map.put(:body_params, %{"foo" =>  100500})
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt
  end

end
