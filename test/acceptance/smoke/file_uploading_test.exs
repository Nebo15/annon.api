defmodule Annon.Acceptance.Smoke.FileUploadingTest do
  @moduledoc false
  use Annon.AcceptanceCase, async: true

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

    "apis/#{api_id}/plugins/proxy"
    |> put_management_url()
    |> put!(%{"plugin" => proxy_plugin})
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
      |> HTTPoison.post!({:multipart, parts}, [{"X-Custom-Header", "custom-value"}, magic_header()])
      |> Map.get(:body)
      |> Poison.decode!

    assert String.starts_with?(response["files"]["file"], "defmodule")
    assert "some-value" == response["form"]["some-name"]
    assert "custom-value" == response["headers"]["X-Custom-Header"]
  end

  test "A POST request with file under a certain name" do
    path = put_public_url("/httpbin")

    parts = [
      {:file, __ENV__.file, {"form-data", [{"name", ~S("loans[file]")}, {"filename", ~S("some-file-name.bson")}]}, []}
    ]

    response =
      path
      |> HTTPoison.post!({:multipart, parts}, [magic_header()])
      |> Map.get(:body)
      |> Poison.decode!

    assert String.starts_with?(response["files"]["loans[file]"], "defmodule")
  end
end
