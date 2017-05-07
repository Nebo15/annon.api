defmodule Annon.Plugins.ValidatorTest do
  @moduledoc false
  use Annon.UnitCase, async: true

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

    settings = %{"rules" => [%{"methods" => ["POST"], "path" => ".*", "schema" => schema}]}

    api = Annon.ConfigurationFactory.build(:api, %{
      plugins: [
        Annon.ConfigurationFactory.build(:validator_plugin, %{
          settings: settings
        })
      ]
    })

    request = %{api: api}

    conn = :post
    |> conn("/", Poison.encode!(%{}))

    conn
    |> Map.put(:body_params, %{"foo" =>  "100500", "bar" => "a"})
    |> Annon.Plugins.Validator.execute(request, settings)
    |> assert_conn_status(422)
    |> assert_halt

    conn
    |> Map.put(:body_params, %{"foo" =>  100500, "bar" => "a"})
    |> Annon.Plugins.Validator.execute(request, settings)
    |> assert_conn_status(nil)
    |> assert_not_halt

    conn
    |> Map.put(:body_params, %{"foo" =>  100500})
    |> Annon.Plugins.Validator.execute(request, settings)
    |> assert_conn_status(422)
    |> assert_halt
  end
end
