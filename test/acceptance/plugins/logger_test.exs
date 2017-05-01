defmodule Annon.Acceptance.Plugins.LoggerTest do
  @moduledoc false
  use Plug.Test
  use Annon.AcceptanceCase, async: true

  alias Annon.Requests.Request

  @random_data %{"data" => "random"}

  defp get_header(response, header) do
    for {k, v} <- response.headers, k === header, do: v
  end

  setup do
    api_path = "/random_api-" <> Ecto.UUID.generate() <> "/"
    api_settings = %{
      request: %{
        methods: ["GET", "POST"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: api_path
      }
    }
    api = :api
    |> build_factory_params(api_settings)
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    proxy_plugin = build_factory_params(:proxy_plugin, %{settings: %{
      scheme: "http",
      host: "127.0.0.1",
      port: 4040,
      path: "/latency"
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(proxy_plugin)
    |> assert_status(201)

    Annon.AutoClustering.do_reload_config()

    %{api_path: api_path}
  end

  describe "logger_plugin" do
    test "logger_plugin", %{api_path: api_path} do
      response = "#{api_path}?key=value"
      |> put_public_url()
      |> post!(@random_data)
      |> assert_status(200)

      id = response
      |> get_header("x-request-id")
      |> Enum.at(0)

      assert(id !== nil, "Plug RequestId is missing or has invalid position")
      result = Request.get_one_by([id: id])

      assert(result !== nil, "Logs are missing")

      uri_to_check = result.request
      |> Map.from_struct
      |> Map.get(:uri)

      assert(uri_to_check === api_path, "Invalid uri has been logged")

      assert result.request.query == %{"key" => "value"}

      body_to_check = result.request
      |> Map.from_struct
      |> Map.get(:body)

      assert(body_to_check === @random_data, "Invalid body has been logged")

      latencies_to_check = result
      |> Map.get(:latencies)
      |> Map.from_struct

      client_latency = Map.get(latencies_to_check, :client_request)
      gateway_latency = Map.get(latencies_to_check, :gateway)
      upstream_latency = Map.get(latencies_to_check, :upstream)

      assert nil != client_latency
      assert nil != gateway_latency
      assert nil != upstream_latency

      assert upstream_latency >= 200
      assert client_latency == gateway_latency + upstream_latency
    end

    test "file body should not be logged", %{api_path: api_path} do
      response =
        api_path
        |> put_public_url()
        |> post!(@random_data, [{"content-disposition", "inline; filename=111.txt"}])
        |> assert_status(200)

      id =
        response
        |> get_header("x-request-id")
        |> Enum.at(0)

      assert(id !== nil, "Plug RequestId is missing or has invalid position")
      result = Request.get_one_by([id: id])

      body_to_check =
        result.response
        |> Map.from_struct
        |> Map.get(:body)
        |> Poison.decode!()
        |> get_in(["data", "response", "body"])

      assert(body_to_check === nil, "Invalid body has been logged")
    end
  end
end
