defmodule Gateway.Acceptance.Plug.ProxyTest do
  use Gateway.AcceptanceCase

  @api_url "apis"
  @consumer_url "consumers"

  @schema %{"type" => "object",
            "properties" => %{
              "foo" => %{ "type" => "number"},
              "bar" => %{ "type" => "string"}
            },
            "required" => ["bar"]
          }

  @consumer_schema %{"type" => "object",
                     "properties" => %{
                       "foo" => %{ "type" => "string"},
                       "bar" => %{ "type" => "number"}
                     },
                     "required" => ["foo"]
                   }

  @consumer_id UUID.uuid1()

  @consumer %{
    external_id: @consumer_id,
    metadata: %{"key": "value"},
  }

  @payload %{"id" => @consumer_id, "name" => "John Doe"}

  test "jwt consumer plugins settings rewrite" do

    data = get_api_model_data()
    |> Map.put(:request,
      %{host: get_host(:public), path: "/proxy/test", port: get_port(:public), scheme: "http", method: "GET"})

    |> Map.put(:plugins, [
      %{
        name: "Proxy",
        is_enabled: true,
        settings: %{
          "proxy_to" => Poison.encode!(%{
            host: get_host(:private),
            path: "/apis",
            port: get_port(:private),
            scheme: "http"
            })
        }
      }
    ])

    @api_url
    |> post(Poison.encode!(data), :private)
    |> assert_status(201)

    body = "proxy/test"
    |> get(:public)
    |> assert_status(200)
    |> get_body()
    |> IO.inspect

  end

end
