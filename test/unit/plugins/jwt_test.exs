defmodule Gateway.Plugins.JWTTest do
  @moduledoc false
  use Gateway.UnitCase, async: true
  import Joken

  @payload %{"name" => "John Doe"}

  setup do
    {:ok, api: Gateway.Factory.insert(:api)}
  end

  test "jwt invalid auth", %{api: api} do
    jwt_plugin = Gateway.Factory.insert(:jwt_plugin, api: api)

    :get
    |> prepare_conn(api.request)
    |> Map.put(:private, %{api_config: %{api | plugins: [jwt_plugin]}})
    |> Map.put(:req_headers, [{"authorization", "Bearer #{jwt_token("super_coolHacker")}bad"}])
    |> Gateway.Plugins.JWT.call(%{})
    |> assert_conn_status(401)
  end

  test "jwt sucessful auth", %{api: api} do
    jwt_plugin = Gateway.Factory.build(:jwt_plugin, %{
      api: api,
      settings: %{"signature" => build_jwt_signature("super_coolHacker")}
    })

    %Plug.Conn{private: %{jwt_token: %Joken.Token{} = jwt_token}} = :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:private, %{api_config: %{ jwt_plugin.api | plugins: [jwt_plugin]}})
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Gateway.Plugins.JWT.call(%{})

    assert @payload == jwt_token.claims
  end

  test "jwt is disabled", %{api: api} do
    jwt_plugin = Gateway.Factory.insert(:jwt_plugin, %{
      api: api,
      is_enabled: false,
      settings: %{"signature" => build_jwt_signature("super_coolHacker")}
    })

    :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:private, %{api_config: jwt_plugin.api})
    |> Gateway.Plugins.JWT.call(%{})
    |> assert_conn_status(nil)
  end

  test "jwt without signature", %{api: api} do
    jwt_plugin = Gateway.Factory.build(:jwt_plugin, %{
      api: api,
      settings: %{}
    })

    :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:private, %{api_config: %{ jwt_plugin.api | plugins: [jwt_plugin]}})
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Gateway.Plugins.JWT.call(%{})
    |> assert_conn_status(501)
  end

  test "jwt required signature in settings" do
    params = %{name: "jwt", settings: %{"some" => "value"}}
    changeset = Gateway.DB.Schemas.Plugin.changeset(%Gateway.DB.Schemas.Plugin{}, params)

    assert %Ecto.Changeset{valid?: false, errors: [signature: {"can't be blank", _}]} = changeset
  end

  test "apis model don't have plugins" do
    api = Gateway.Factory.build(:api)

    :get
    |> prepare_conn(api.request)
    |> Gateway.Plugins.JWT.call(%{})
    |> assert_conn_status(nil)
  end

  defp prepare_conn(method, request) do
    method
    |> conn(request.path, Poison.encode!(%{}))
    |> Map.put(:host, request.host)
    |> Map.put(:port, request.port)
    |> Map.put(:scheme, String.to_atom(request.scheme))
  end

  defp jwt_token(signature) do
    @payload
    |> token
    |> sign(hs256(signature))
    |> get_compact
  end
end
