defmodule Gateway.Plugins.ValidatorTest do
  use Gateway.HTTPTestHelper

  test "user is redirected when current_user is not assigned" do
    content = %{
      "name" => "New name",
      "surmame" => "Surname",
      "age" => "100500",
      "foo" =>  100500
    }

    schema = %{
      "type" => "object",
      "properties" => %{
        "foo" => %{
          "type" => "number"
        }
      }
    }

#    ExJsonSchema.Validator.valid?(schema, content)
#    |> IO.inspect

    :get
    |> conn("/", Poison.encode!(content))
    |> assign(:body, content)
    |> assign(:schema, schema)
    |> Gateway.Plugins.Validator.call(%{})
    |> assert_halt



  end

end