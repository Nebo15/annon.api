defmodule Gateway.ConfigReloaderTest do
  use Gateway.UnitCase

  test "reload the config cache if it changes" do
    {:ok, api_model} =
      get_api_model_data()
      |> Gateway.DB.Models.API.create()

    # check the config

    new_contents = %{
      "name" => "New name"
    }

    :put
    |> conn("/apis/#{api_model.id}", Poison.encode!(new_contents))
    |> put_req_header("content-type", "application/json")
    |> Gateway.PrivateRouter.call([])

    [{_, api}] = :ets.lookup(:config, {:api, api_model.id})

    assert api.name == "New name"
  end

  @tag cluster: true
  test "correct communication between processes" do
    Gateway.Cluster.spawn()

    {:ok, api} =
      %{
        name: "Test api",
        request: %{
          scheme: "HTTP",
          host: "example.com",
          port: "80",
          path: "/",
          method: "GET"
        }
      }
      |> Gateway.DB.Models.API.create()
      |> IO.inspect

# Process.sleep(5000)

    assert "Test api" == check_api_on_node(api.id, "name", 6001)
    assert "Test api" == check_api_on_node(api.id, "name", 6003)

    # HTTPoison.put!("http://localhost:6001/apis/#{api.id}", Poison.encode!(%{name: "New name"}))
    :put
    |> conn("/apis/#{api.id}", Poison.encode!(%{name: "New name"}))
    |> put_req_header("content-type", "application/json")
    |> Gateway.PrivateRouter.call([])

    Gateway.DB.Repo.get(Gateway.DB.Models.API, api.id)
    |> IO.inspect

    assert "New name" == check_api_on_node(api.id, "name", 6001)
    assert "New name" == check_api_on_node(api.id, "name", 6003)
  end

  defp check_api_on_node(api_id, field, port) do
    HTTPoison.get!("http://localhost:#{port}/apis/#{api_id}")
    |> Map.get(:body)
    |> Poison.decode!
    |> get_in(["data", field])
  end
end
