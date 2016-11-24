defmodule Gateway.Acceptance.Smoke.FileUploadingTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  setup do
    api = :api
    |> build_factory_params(%{
      name: "An HTTPBin service endpoint",
      request: %{
        methods: ["POST"],
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
      strip_api_path: true
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(proxy_plugin)
    |> assert_status(201)

    :ok
  end

  test "A POST request from user reaches upstream" do
    path = put_public_url("/httpbin")

    parts = [
      {:file, __ENV__.file}, {"some-name", "some-value"}
    ]

    response =
      path
      |> HTTPoison.post!({:multipart, parts}, [{"X-Custom-Header", "custom-value"}, magic_cookie()])
      |> Map.get(:body)
      |> Poison.decode!

    assert String.starts_with?(response["files"]["file"], "defmodule")
    assert "some-value" == response["form"]["some-name"]
    assert "custom-value" == response["headers"]["X-Custom-Header"]
  end
end
