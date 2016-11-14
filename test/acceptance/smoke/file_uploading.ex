defmodule Gateway.Acceptance.Smoke.ProxyTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  setup do
    api = :api
    |> build_factory_params(%{
      name: "An HTTPBin service endpoint",
      request: %{
        method: ["POST"],
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
      path: "/post",
      strip_request_path: true
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(proxy_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    :ok
  end

  test "A POST request from user reaches upstream" do
    response =
      HTTPoison.post!("https://httpbin.org/post", {:multipart, [{:file, __ENV__.file}]})
      |> Map.get(:body)
      |> Poison.decode!

    assert String.starts_with?(response["files"]["file"], "defmodule")
  end
end
