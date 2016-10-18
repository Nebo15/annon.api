defmodule Gateway.Plugins.JWTTest do
  @moduledoc """
  Testing Gateway.Plugins.ApiLoader
  """

  use Gateway.HTTPTestHelper
  alias Gateway.DB.Models.API, as: APIModel
  import Joken

  @payload %{ "name" => "John Doe" }

  test "jwt invalid auth" do

    data = get_api_model_data()
    |> Map.put(:plugins, [%{name: "JWT", is_enabled: true, settings: %{"signature" => "super_coolHacker"}}])

    {:ok, %APIModel{request: request} = model} = APIModel.create(data)

    %Plug.Conn{} = conn = :get
    |> conn(request.path, Poison.encode!(%{}))
    |> put_conn_req(request)
    |> Map.put(:private, %{api_config: model})
    |> Gateway.Plugins.JWT.call(%{})

    assert 401 == conn.status
  end

  test "jwt sucessful auth" do

    data = get_api_model_data()
    |> Map.put(:plugins, [%{name: "JWT", is_enabled: true, settings: %{"signature" => "super_coolHacker"}}])

    {:ok, %APIModel{request: request} = model} = APIModel.create(data)

    compact = @payload
    |> token
    |> sign(hs256("super_coolHacker"))
    |> get_compact

    %Plug.Conn{private: %{jwt_token: %Joken.Token{} = jwt_token}} = :get
    |> conn(request.path, Poison.encode!(%{}))
    |> put_conn_req(request)
    |> Map.put(:private, %{api_config: model})
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{compact}"}])
    |> Gateway.Plugins.JWT.call(%{})

    assert @payload == jwt_token.claims
  end

  defp put_conn_req(conn, request) do
    conn
    |> Map.put(:host, request.host)
    |> Map.put(:port, request.port)
    |> Map.put(:scheme, String.to_atom(request.scheme))
  end

end
