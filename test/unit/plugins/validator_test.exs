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
    |> assign(:body, %{"foo" =>  "100500", "bar" => "a"})
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt

    connect
    |> assign(:body, %{"foo" =>  100500, "bar" => "a"})
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_not_halt

    connect
    |> assign(:body, %{"foo" =>  100500})
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt
  end

end