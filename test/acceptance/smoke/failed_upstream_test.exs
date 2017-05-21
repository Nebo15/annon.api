defmodule Annon.Acceptance.Smoke.FailedUpstreamTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

  setup do
    api = :api
    |> build_factory_params(%{
      name: "An HTTPBin service endpoint",
      request: %{
        methods: ["GET"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: "/error",
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    proxy_plugin = :proxy_plugin
    |> build_factory_params(%{settings: %{
      scheme: "http",
      host: "errorzkdjdsdhsifosdifhdsfsodihf.co",
      port: 80,
      path: "/get",
      strip_api_path: true
    }})

    "apis/#{api_id}/plugins/proxy"
    |> put_management_url()
    |> put!(%{"plugin" => proxy_plugin})
    |> assert_status(201)

    :ok
  end

  test "A request from non-working upstream returns HTTP 502" do
    response =
      "/error?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.get!([magic_header()])

    assert_status(response, 502)

    decoded_response =
      response
      |> Map.get(:body)
      |> Poison.decode!

    assert %{
      "type" => "upstream_error",
      "message" => "Upstream is unavailable with reason :nxdomain"
    } == decoded_response
  end
end
