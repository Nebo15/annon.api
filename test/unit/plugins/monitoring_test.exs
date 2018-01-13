defmodule Annon.Plugins.MonitoringTest do
  @moduledoc false
  use Annon.ConnCase, router: Annon.PublicAPI.Router
  alias Annon.Factories.Configuration, as: ConfigurationFactory

  setup %{conn: conn} do
    :sys.replace_state DogStat, fn state ->
      Map.update!(state, :sink, fn _prev_state -> [] end)
    end

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> put_req_header("content-type", "application/json")

    %{conn: conn}
  end

  test "metrics are collected", %{conn: conn} do
    api = ConfigurationFactory.insert(:api, %{
      name: "Montoring Test api",
      request: ConfigurationFactory.build(:api_request, %{host: "www.example.com", path: "/apis"})
    })

    ConfigurationFactory.insert(:proxy_plugin, %{
      name: "proxy",
      is_enabled: true,
      api: api,
      settings: %{
        upstream: %{
          scheme: "http",
          host: "localhost",
          port: 4040,
          path: "/apis"
        }
      }
    })

    conn
    |> get("/apis")
    |> json_response(200)

    [%{header: [_, "test", 46], key: "latencies.gateway",
       options: [tags: ["http.status:200", "http.host:www.example.com",
         "http.method:GET", "http.port:80", "api.name:Montoring Test api",
         "api.id:" <> _,
         "request.id:" <> _], sample_rate: 1],
       type: :histogram, value: _},
     %{header: [_, "test", 46], key: "latencies.upstream",
       options: [tags: ["http.status:200", "http.host:www.example.com",
         "http.method:GET", "http.port:80", "api.name:Montoring Test api",
         "api.id:" <> _,
         "request.id:" <> _], sample_rate: 1],
       type: :histogram, value: _},
     %{header: [_, "test", 46], key: "latencies.client",
       options: [tags: ["http.status:200", "http.host:www.example.com",
         "http.method:GET", "http.port:80", "api.name:Montoring Test api",
         "api.id:" <> _,
         "request.id:" <> _], sample_rate: 1],
       type: :histogram, value: _},
     %{header: [_, "test", 46], key: "responses.count",
       options: [tags: ["http.status:200", "http.host:www.example.com",
         "http.method:GET", "http.port:80", "api.name:Montoring Test api",
         "api.id:" <> _,
         "request.id:" <> _], sample_rate: 1],
       type: :counter, value: "1"},
     %{header: [_, "test", 46], key: "request.count",
       options: [tags: ["http.host:www.example.com", "http.method:GET",
         "http.port:80", "api.name:Montoring Test api",
         "api.id:" <> _,
         "request.id:" <> _], sample_rate: 1],
       type: :counter, value: "1"}] = sent()
  end

  defp sent(name \\ DogStat),
    do: state(name).sink

  defp state(name),
    do: :sys.get_state(name)
end
