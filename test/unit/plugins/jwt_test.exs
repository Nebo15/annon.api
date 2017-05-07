defmodule Annon.Plugins.JWTTest do
  @moduledoc false
  use Annon.UnitCase, async: true
  import Joken

  @payload %{"name" => "John Doe"}

  setup do
    {:ok, api: Annon.ConfigurationFactory.insert(:api)}
  end

  test "jwt invalid auth", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.insert(:jwt_plugin, api: api)

    :get
    |> prepare_conn(api.request)
    |> Map.put(:req_headers, [{"authorization", "Bearer #{jwt_token("super_coolHacker")}bad"}])
    |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)
    |> assert_conn_status(401)
  end

  test "jwt sucessful auth", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.build(:jwt_plugin, %{
      api: api,
      settings: %{"signature" => build_jwt_signature("super_coolHacker")}
    })

    %Plug.Conn{private: %{jwt_token: %Joken.Token{} = jwt_token}} = :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)

    assert @payload == jwt_token.claims
  end

  test "jwt with not base64-encoded signature", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.build(:jwt_plugin, %{
      api: api,
      settings: %{"signature" => "teststring"}
    })

    :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)
    |> assert_conn_status(501)
  end

  test "jwt without authorization header", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.build(:jwt_plugin, %{
      api: api,
      settings: %{"signature" => build_jwt_signature("super_coolHacker")}
    })

    %Plug.Conn{private: private} =
      :get
      |> prepare_conn(jwt_plugin.api.request)
      |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)

    refute Map.has_key?(private, :jwt_token)
  end

  test "jwt with invalid authorization type", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.build(:jwt_plugin, %{
      api: api,
      settings: %{"signature" => build_jwt_signature("super_coolHacker")}
    })

    %Plug.Conn{private: private} =
      :get
      |> prepare_conn(jwt_plugin.api.request)
      |> Map.put(:req_headers, [ {"authorization", "Unkown #{jwt_token("super_coolHacker")}"}])
      |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)

    refute Map.has_key?(private, :jwt_token)
  end

  test "jwt is disabled", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.insert(:jwt_plugin, %{
      api: api,
      is_enabled: false,
      settings: %{"signature" => build_jwt_signature("super_coolHacker")}
    })

    :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:private, %{api_config: jwt_plugin.api})
    |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)
    |> assert_conn_status(nil)
  end

  test "jwt without signature", %{api: api} do
    jwt_plugin = Annon.ConfigurationFactory.build(:jwt_plugin, %{
      api: api,
      settings: %{}
    })

    :get
    |> prepare_conn(jwt_plugin.api.request)
    |> Map.put(:req_headers, [ {"authorization", "Bearer #{jwt_token("super_coolHacker")}"}])
    |> Annon.Plugins.JWT.execute(%{api: api}, jwt_plugin.settings)
    |> assert_conn_status(501)
  end

  test "jwt required signature in settings" do
    params = %{name: "jwt", settings: %{"some" => "value"}}
    changeset =
      %Annon.Configuration.Schemas.Plugin{}
      |> Ecto.Changeset.change(params)
      |> Annon.Plugins.JWT.SettingsValidator.validate_settings()

    assert %Ecto.Changeset{valid?: false, errors: errors} = changeset
    assert settings: {"required property signature was not present", [validation: :required]} in errors
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
