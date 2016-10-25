defmodule Gateway.Acceptance.Plug.IdempotencyTest do
  use Gateway.AcceptanceCase

  @idempotency_key UUID.uuid1()

  test "test idempotency DELETE request" do

    %HTTPoison.Response{body: body} = "GET"
    |> api_idempotency_data("/idempotency")
    |> http_api_create()

    "DELETE"
    |> api_idempotency_data("/idempotency", Poison.decode!(body)["data"]["id"])
    |> http_api_create()

    "idempotency"
    |> delete(:public, [{"x-idempotency-key", @idempotency_key}])
    |> assert_status(200)
  end

  def api_idempotency_data(method, path) do
    get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: path, port: get_port(:public), scheme: "http", method: method})
    |> Map.put(:plugins, [
      %{name: "Idempotency", is_enabled: true, settings: %{"key" => 100}},
    ])
  end

  def api_idempotency_data(method, path, api_id) when is_integer(api_id) do
    api_idempotency_data(method, path, Integer.to_string(api_id))
  end
  def api_idempotency_data(method, path, api_id) do
    data = method
    |> api_idempotency_data(path)

    Map.put(data, :plugins, List.insert_at(
      data.plugins,
      -1,
       %{ name: "Proxy", is_enabled: true,
          settings: %{
            "proxy_to" => Poison.encode!(%{
              host: get_host(:private),
              path: "/apis/#{api_id}",
              port: get_port(:private),
              scheme: "http"
              })
          }
        }
      ))
  end
end
