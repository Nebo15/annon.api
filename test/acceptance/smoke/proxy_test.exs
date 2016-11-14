defmodule Gateway.Acceptance.Smoke.ProxyTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  setup do
    api = :api
    |> build_factory_params(%{
      name: "An HTTPBin service endpoint",
      request: %{
        methods: ["GET"],
        scheme: "http",
        host: get_endpoint_host(:public),
        port: get_endpoint_port(:public),
        path: "/httpbin",
      }
    })
    |> create_api()
    |> get_body()

    api_id = get_in(api, ["data", "id"])

    proxy_plugin = :proxy_plugin
    |> build_factory_params(%{settings: %{
      scheme: "http",
      host: "httpbin.org",
      port: 80,
      path: "/get",
      strip_api_path: true
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(proxy_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    :ok
  end

  test "A PUT request from user reaches upstream" do
    response =
      "/httpbin?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.get!([{"my-custom-header", "some-value"}])
      |> Map.get(:body)
      |> Poison.decode!

    assert "my_value" == response["args"]["my_param"]
    assert "some-value" == response["headers"]["My-Custom-Header"]
  end

  test "A POST request from user reaches upstream" do
    response =
      "/httpbin?my_param=my_value"
      |> put_public_url()
      |> HTTPoison.get!
      |> Map.get(:body)
      |> Poison.decode!

    HTTPoison.post("localhost:8080/post", {:multipart, [{:file, "test/test_helper.exs"}, {"name", "value"}]})

    assert "my_value" == response["args"]["my_param"]
  end
end
