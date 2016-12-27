defmodule Gateway.Acceptance.Plugins.CORSTest do
  @moduledoc false
  use Plug.Test
  use Gateway.AcceptanceCase, async: true

  defp get_header(response, header) do
    for {k, v} <- response.headers, k === header, do: v
  end

  @origin "http://www.example.com"

  setup do
    api_path = "/random_api-" <> Ecto.UUID.generate() <> "/"
    api_settings = %{
      request: %{
        methods: ["GET", "OPTIONS"],
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

    cors_plugin = build_factory_params(:cors_plugin, %{settings: %{
      origin: [@origin]
    }})

    "apis/#{api_id}/plugins"
    |> put_management_url()
    |> post!(cors_plugin)
    |> assert_status(201)

    Gateway.AutoClustering.do_reload_config()

    %{api_path: api_path}
  end

  test "cors_plugin", %{api_path: api_path} do
    resp = api_path
    |> put_public_url()
    |> options!([{"origin", @origin}])

    allow_origin_header = resp |> get_header("access-control-allow-origin") |> Enum.at(0)

    assert @origin == allow_origin_header

    assert 1 == length(get_header(resp, "access-control-expose-headers"))
    assert 1 == length(get_header(resp, "access-control-allow-credentials"))
    assert 1 == length(get_header(resp, "access-control-max-age"))
    assert 1 == length(get_header(resp, "access-control-allow-headers"))
    assert 1 == length(get_header(resp, "access-control-allow-methods"))

    resp = api_path
    |> put_public_url()
    |> get!([{"origin", @origin}])

    allow_origin_header = resp |> get_header("access-control-allow-origin") |> Enum.at(0)

    assert @origin == allow_origin_header

    assert 1 == length(get_header(resp, "access-control-expose-headers"))
    assert 1 == length(get_header(resp, "access-control-allow-credentials"))
  end
end
