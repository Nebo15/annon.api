defmodule Annon.Plugins.ValidatorTest do
  @moduledoc false
  use Annon.ConnCase, async: true, router: Annon.PublicAPI.Router
  alias Annon.Factories.Configuration, as: ConfigurationFactory

  setup %{conn: conn} do
    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  test "validator plugin", %{conn: conn} do
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

    api = ConfigurationFactory.build(:api, %{
      plugins: [
        ConfigurationFactory.build(:validator_plugin, %{
          settings: settings
        })
      ]
    })

    request = %{api: api}

    conn = Plug.Adapters.Test.Conn.conn(conn, :post, "/", Poison.encode!(%{}))

    assert %Plug.Conn{halted: true, status: 422} =
      conn
      |> Map.put(:body_params, %{"foo" =>  "100500", "bar" => "a"})
      |> Annon.Plugins.Validator.execute(request, settings)

    assert %Plug.Conn{halted: false, status: nil} =
      conn
      |> Map.put(:body_params, %{"foo" =>  100500, "bar" => "a"})
      |> Annon.Plugins.Validator.execute(request, settings)

    assert %Plug.Conn{halted: true, status: 422} =
      conn
      |> Map.put(:body_params, %{"foo" =>  100500})
      |> Annon.Plugins.Validator.execute(request, settings)
  end
end
