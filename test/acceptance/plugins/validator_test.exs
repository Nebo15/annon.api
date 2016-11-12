defmodule Gateway.Acceptance.Plugin.ValidatorTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  @schema %{"type" => "object",
            "properties" => %{"foo" => %{"type" => "number"}, "bar" => %{ "type" => "string"}},
            "required" => ["bar"]}

  setup do
    api_path = "/my_validated_api"
    api = :api
    |> build_factory_params(%{
      request: %{
        method: ["GET", "POST", "PUT", "DELETE"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    %{api_id: api_id, api_path: api_path}
  end

  test "post hook with empty data", %{api_id: api_id, api_path: api_path} do
    validator_plugin = :validator_plugin
    |> build_factory_params(%{settings: %{
      schema: Poison.encode!(@schema)
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(validator_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config

    assert %{
      "error" => %{"type" => "validation_failed"}
    } = api_path
    |> put_public_url()
    |> post!(%{data: "aaaa"})
    |> assert_status(422)
    |> get_body()

    api_path
    |> put_public_url()
    |> post!(%{bar: "foo"})
    |> assert_status(404)
  end
end
