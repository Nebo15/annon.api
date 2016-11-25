defmodule Gateway.Acceptance.Plugins.ACL3Test do
  @moduledoc false
  use Gateway.AcceptanceCase, async: true

  @jwt_secret "secret"

  describe "JWT Strategy" do
    test "Auth0 Flow is supported3" do
      body = %{
        name: "An HTTPBin service endpoint",
        request: %{
          methods: ["GET"],
          scheme: "http",
          host: "localhost",
          port: 1234,
          path: "/httpbin",
        }
      }

      %{ "data" => %{ "id" => id } } =
      HTTPoison.post!("http://localhost:5001/apis", Poison.encode!(body), [{"Content-Type", "application/json"}, magic_header()])
      |> Map.get(:body)
      |> Poison.decode!(body)

      body2 = %{
        name: "proxy",
        is_enabled: true,
        settings: %{
          "scheme" => "http",
          "host" => "httpbin.org",
          "port" => 80,
          "path" => "/get"
        }
      }

      resp =
        HTTPoison.post!("http://localhost:5001/apis/#{id}/plugins/", Poison.encode!(body2), [{"Content-Type", "application/json"}, magic_header()])
        |> Map.get(:body)
        |> Poison.decode!(body)

      assert resp["data"]["id"] > 1
    end
  end
end
