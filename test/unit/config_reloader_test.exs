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

  test "correct communication between processes" do
    Application.ensure_started(:porcelain)

    host = "localhost"
    cookie = "test_cookie"

    nodes =
      [
        %{ pub: 6000, priv: 6001, name: "testnode1" },
        %{ pub: 6002, priv: 6003, name: "testnode2" }
      ]
      |> Enum.map(fn %{pub: pub, priv: priv, name: name} ->
           sname = "#{name}@#{host}"

           env_vars = [
             { "GATEWAY_PUBLIC_PORT", pub },
             { "GATEWAY_PRIVATE_PORT", priv }
           ]
       end)

    Enum.each(nodes, fn {name, proc} ->
      name |> IO.inspect
      :rpc.eval_everywhere([name], :init, :stop, [])
      # Porcelain.Process.signal(proc, :kill)
      # |> IO.inspect
    end)
  end
end
