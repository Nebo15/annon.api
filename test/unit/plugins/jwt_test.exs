defmodule Gateway.Plugins.JWTTest do
  @moduledoc """
  Testing Gateway.Plugins.APILoader
  """

  use Gateway.UnitCase
  alias Gateway.DB.Schemas.API, as: APISchema
  import Joken

  @payload %{ "name" => "John Doe" }
  @plugin_data [%{name: "jwt", is_enabled: true, settings: %{"signature" => "super_coolHacker"}}]

  test "jwt invalid auth" do
    {:ok, %APISchema{request: request} = model} = create_api()

    %Plug.Conn{} = conn = :get
    |> prepare_conn(request)
    |> Map.put(:private, %{api_config: model})
    |> Gateway.Plugins.JWT.call(%{})

    assert 401 == conn.status

    %Plug.Conn{} = conn = :get
    |> prepare_conn(request)
    |> Map.put(:private, %{api_config: model})
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}bad"}])
    |> Gateway.Plugins.JWT.call(%{})

    assert 401 == conn.status
  end

  test "jwt sucessful auth" do

    {:ok, %APISchema{request: request} = model} = create_api()

    %Plug.Conn{private: %{jwt_token: %Joken.Token{} = jwt_token}} = :get
    |> prepare_conn(request)
    |> Map.put(:private, %{api_config: model})
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Gateway.Plugins.JWT.call(%{})

    assert @payload == jwt_token.claims
  end

  test "jwt is disabled" do
    data = get_api_model_data()
    |> Map.put(:plugins, [%{name: "jwt", is_enabled: false, settings: %{"signature" => "super_coolHacker"}}])

    {:ok, %APISchema{request: request} = model} = APISchema.create(data)

    %Plug.Conn{} = conn = :get
    |> prepare_conn(request)
    |> Map.put(:private, %{api_config: model})
    |> Gateway.Plugins.JWT.call(%{})

    assert nil == conn.status
  end

  test "jwt required signature in settings" do
    data = get_api_model_data()
    |> Map.put(:plugins, [%{name: "jwt", is_enabled: true, settings: %{"some" => "value"}}])

    assert {:error, %Ecto.Changeset{valid?: false}} = APISchema.create(data)
  end

  test "apis model don't have plugins'" do
    {:ok, %APISchema{request: request}} = create_api()

    %Plug.Conn{} = conn = :get
    |> prepare_conn(request)
    |> Gateway.Plugins.JWT.call(%{})

    assert nil == conn.status
  end

  defp prepare_conn(method, request) do
    method
    |> conn(request.path, Poison.encode!(%{}))
    |> Map.put(:host, request.host)
    |> Map.put(:port, request.port)
    |> Map.put(:scheme, String.to_atom(request.scheme))
  end

  defp create_api do
    data = get_api_model_data()
    |> Map.put(:plugins, @plugin_data)

     APISchema.create(data)
  end

  defp jwt_token(signature) do
    @payload
    |> token
    |> sign(hs256(signature))
    |> get_compact
  end
end
