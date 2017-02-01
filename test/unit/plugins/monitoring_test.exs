defmodule Gateway.Plugins.MonitoringTest do
  @moduledoc false
  use Gateway.UnitCase, async: true

  test "metrics work properly" do
    make_connection()

    assert [
      "test.response_count:1|c|#http_host:www.example.com,http_method:GET,http_port:80,api_name:unknown,api_id:unknown,http_status:200",
      "test.latency:" <> _,
      "test.request_count:1|c|#http_host:www.example.com,http_method:GET,http_port:80,api_name:unknown,api_id:unknown",
      "test.request_size:28|h|#http_host:www.example.com,http_method:GET,http_port:80,api_name:unknown,api_id:unknown"
    ] = sent()
  end

  defp make_connection do
    api = Gateway.Factory.insert(:api, %{
      name: "Montoring Test api",
      request: Gateway.Factory.build(:request, %{host: "www.example.com", path: "/apis"})
    })

    Gateway.Factory.insert(:proxy_plugin, %{
      name: "proxy",
      is_enabled: true,
      api: api,
      settings: %{
        scheme: "http",
        host: "localhost",
        port: 4040,
        path: "/apis"
      }
    })

    "/apis"
    |> call_public_router()
  end

  defp sent(name \\ExStatsD),
    do: state(name).sink

  defp state(name),
    do: :sys.get_state(name)
end
