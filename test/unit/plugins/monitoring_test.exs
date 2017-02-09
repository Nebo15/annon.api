defmodule Gateway.Plugins.MonitoringTest do
  @moduledoc false
  use Gateway.UnitCase

  setup do
    :sys.replace_state ExStatsD, fn state ->
      Map.update!(state, :sink, fn _prev_state -> [] end)
    end
  end

  test "metrics work properly" do
    make_connection()

    assert [
      "test.response_count:1|c|#http_host:www.example.com,http_method:GET,http_port:80"
        <> ",api_name:Montoring Test api," <> _,
      "test.latency:" <> _,
      "test.request_count:1|c|#http_host:www.example.com,http_method:GET,http_port:80"
        <> ",api_name:Montoring Test api" <> _,
      "test.request_size:28|h|#http_host:www.example.com,http_method:GET,http_port:80"
        <> ",api_name:Montoring Test api" <> _,
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
