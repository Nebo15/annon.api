defmodule Annon.Plugins.AuthTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  import Annon.TestHelpers
  alias Annon.ConfigurationFactory
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth

  describe "settings_validation_schema/3" do
    test "accepts oauth config" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "strategy" => "oauth",
        "url_template" => "http://example.com/"
      }}}

      assert %Ecto.Changeset{valid?: true} = Auth.validate_settings(changeset)
    end

    test "accepts jwt config" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "strategy" => "jwt",
        "secret" => Base.encode64("a_secret_signature"),
        "third_party_resolver" => false,
        "algorithm" => "HS256"
      }}}

      assert %Ecto.Changeset{valid?: true} = Auth.validate_settings(changeset)
    end

    test "accepts jwt config with third party resolver" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "strategy" => "jwt",
        "secret" => Base.encode64("a_secret_signature"),
        "third_party_resolver" => true,
        "url_template" => "http://example.com/",
        "algorithm" => "HS256"
      }}}

      assert %Ecto.Changeset{valid?: true} = Auth.validate_settings(changeset)
    end

    test "validates jwt signature" do
      changeset = %Ecto.Changeset{valid?: true, changes: %{settings: %{
        "strategy" => "jwt",
        "secret" => "not_encoded_string",
        "third_party_resolver" => true,
        "url_template" => "http://example.com/",
        "algorithm" => "HS256"
      }}}

      assert %Ecto.Changeset{valid?: false, errors: errors} = Auth.validate_settings(changeset)
      assert ["settings.secret": {"is not Base64 encoded", [validation: :cast]}] == errors
    end
  end

  describe "execute/3" do
    setup %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> put_req_header("content-type", "application/json")

      mock_conf = Confex.get_map(:annon_api, :acceptance)[:mock]
      mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/"

      %{
        conn: conn,
        mock_url: mock_url
      }
    end

    test "returns unauthorized when token is not set", %{conn: conn} do
      auth_jwt_plugin = ConfigurationFactory.params_for(:auth_plugin_with_jwt)
      settings = auth_jwt_plugin.settings
      assert %{
        "error" => %{
          "message" => "Authorization header is not set or doesn't contain Bearer token",
          "type" => "access_denied"
        }
      } = conn
      |> Auth.execute(nil, settings)
      |> json_response(401)
    end

    test "returns unauthorized when token is invalid", %{conn: conn} do
      auth_jwt_plugin = ConfigurationFactory.params_for(:auth_plugin_with_jwt)
      settings = auth_jwt_plugin.settings

      jwt_token = jwt_token_factory(%{}, Base.encode64("invalid_secret"))

      assert %{
        "error" => %{
          "message" => "JWT token is invalid",
          "type" => "access_denied"
        }
      } = conn
      |> put_req_header("authorization", "Bearer " <> jwt_token)
      |> Auth.execute(nil, settings)
      |> json_response(401)
    end

    test "oauth strategy is not found", %{conn: conn} do
      mock_url = "httpbin.org/status/404"

      settings = %{
        "strategy" => "oauth",
        "url_template" => mock_url
      }

      assert %{
        "error" => %{
          "message" => "Invalid access token",
          "type" => "access_denied"
        }
      } = conn
      |> put_req_header("authorization", "Bearer access_token")
      |> Auth.execute(nil, settings)
      |> json_response(401)
    end

    test "jwt strategy is supported", %{conn: conn} do
      consumer_id = "bob"
      consumer_scope = "api:request"

      auth_jwt_plugin = ConfigurationFactory.params_for(:auth_plugin_with_jwt)
      settings = auth_jwt_plugin.settings

      payload = %{"consumer_scope" => consumer_scope, "consumer_id" => consumer_id}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert %{assigns: %{consumer: consumer}} = conn =
        conn
        |> put_req_header("authorization", "Bearer " <> jwt_token)
        |> Auth.execute(nil, settings)

      assert [{"x-consumer-id", "bob"}, {"x-consumer-scope", "api:request"}] == conn.assigns.upstream_request.headers

      assert %Consumer{
        id: "bob",
        metadata: ^payload,
        scope: "api:request"
      } = consumer
    end

    test "jwt strategy with third-party resolver is supported", %{conn: conn} do
      consumer_id = "bob"

      mock_conf = Confex.get_map(:annon_api, :acceptance)[:mock]
      mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/auth/consumers/" <> consumer_id

      settings = %{
        "strategy" => "jwt",
        "secret" => Base.encode64("a_secret_signature"),
        "third_party_resolver" => true,
        "url_template" => mock_url,
        "algorithm" => "HS256"
      }

      payload = %{"consumer_id" => consumer_id}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert %{assigns: %{consumer: consumer}} = conn =
        conn
        |> put_req_header("authorization", "Bearer " <> jwt_token)
        |> Auth.execute(nil, settings)

      assert [{"x-consumer-id", "bob"}, {"x-consumer-scope", "api:access"}] == conn.assigns.upstream_request.headers

      assert %Consumer{
        id: "bob",
        metadata: ^payload,
        scope: "api:access"
      } = consumer
    end

    test "oauth strategy is supported", %{conn: conn} do
      access_token = "random_token"

      mock_conf = Confex.get_map(:annon_api, :acceptance)[:mock]
      mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/auth/tokens/" <> access_token

      settings = %{
        "strategy" => "oauth",
        "url_template" => mock_url
      }

      assert %{assigns: %{consumer: consumer}} = conn =
        conn
        |> put_req_header("authorization", "Bearer " <> access_token)
        |> Auth.execute(nil, settings)

      assert [{"x-consumer-id", "bob"}, {"x-consumer-scope", "api:access"}] == conn.assigns.upstream_request.headers

      assert %Consumer{
        id: "bob",
        scope: "api:access"
      } = consumer
    end
  end
end
