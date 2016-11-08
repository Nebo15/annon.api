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
    %APISchema{request: request} = model = Gateway.Factory.insert(:api_with_default_plugins)

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
    jwt_plugin = Gateway.Factory.build(:jwt_plugin, settings: %{"signature" => "super_coolHacker"})

    %Plug.Conn{private: %{jwt_token: %Joken.Token{} = jwt_token}} = :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:private, %{api_config: %{ jwt_plugin.api | plugins: [jwt_plugin]}})
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Gateway.Plugins.JWT.call(%{})

    assert @payload == jwt_token.claims
  end

  test "jwt is disabled" do
    jwt_plugin = Gateway.Factory.build(:jwt_plugin, is_enabled: false, settings: %{"signature" => "super_coolHacker"})

    %Plug.Conn{} = conn = :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:private, %{api_config: jwt_plugin.api})
    |> Gateway.Plugins.JWT.call(%{})

    assert nil == conn.status
  end

  test "jwt required signature in settings" do
    params = %{name: "jwt", settings: %{"some" => "value"}}
    changeset = Gateway.DB.Schemas.Plugin.changeset(%Gateway.DB.Schemas.Plugin{}, params)

    assert %Ecto.Changeset{valid?: false, errors: [signature: {"can't be blank", _}]} = changeset
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
