defmodule Annon.Plugins.MonitoringTest do
  @moduledoc false
  use Annon.UnitCase

  setup do
    :sys.replace_state Annon.Monitoring.MetricsCollector, fn state ->
      Map.update!(state, :sink, fn _prev_state -> [] end)
    end
  end

  test "metrics work properly" do
    api = Annon.ConfigurationFactory.insert(:api, %{
      name: "Montoring Test api",
      request: Annon.ConfigurationFactory.build(:api_request, %{host: "www.example.com", path: "/apis"})
    })

    Annon.ConfigurationFactory.insert(:proxy_plugin, %{
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

    [
      %{
          key: "response_count",
          options: [tags: ["http_host:www.example.com", "http_method:GET",
                          "http_port:80", "api_name:Montoring Test api",
                          "api_id:" <> _,
                          "request_id:" <> _, "http_status:200"]],
          type: :counter,
          value: "1"
        },
        %{
          key: "latency",
          options: [tags: ["http_host:www.example.com", "http_method:GET",
                          "http_port:80", "api_name:Montoring Test api",
                          "api_id:" <> _,
                          "request_id:" <> _, "http_status:200"]],
          type: :timing, value: _
        },
        %{
          key: "request_count",
          options: [tags: ["http_host:www.example.com", "http_method:GET",
                          "http_port:80", "api_name:Montoring Test api",
                          "api_id:" <> _,
                          "request_id:" <> _]],
          type: :counter,
          value: "1"
        },
        %{
          key: "request_size",
          options: [tags: ["http_host:www.example.com", "http_method:GET",
                          "http_port:80", "api_name:Montoring Test api",
                          "api_id:" <> _,
                          "request_id:" <> _]],
          type: :histogram,
          value: _
      }
    ] = sent()
  end

  defp sent(name \\ Annon.Monitoring.MetricsCollector),
    do: state(name).sink

  defp state(name),
    do: :sys.get_state(name)
end
