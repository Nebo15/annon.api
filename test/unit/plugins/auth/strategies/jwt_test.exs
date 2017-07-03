defmodule Annon.Plugins.Auth.Strategies.JWTTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  import Annon.Factories.JWT
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth.Strategies.JWT, as: JWTStrategy

  describe "fetch_consumer/3 without third party resolver" do
    setup do
      {:ok, %{
        "secret" => Base.encode64("a_secret_signature"),
        "third_party_resolver" => false,
        "algorithm" => "HS256"
      }}
    end

    test "returns consumer when token is valid", settings do
      # String Consumer ID
      payload = %{"consumer_scope" => "httpbin:read", "consumer_id" => "andrew"}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: "httpbin:read"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)

      # Numeric Consumer ID
      payload = %{"consumer_scope" => "httpbin:read", "consumer_id" => 12325}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert {:ok, %Consumer{
        id: "12325",
        metadata: ^payload,
        scope: "httpbin:read"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "returns consumer when token does not carry scopes", settings do
      payload = %{"consumer_id" => "andrew"}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: ""
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "returns consumer when consumer id is in app_metadata", settings do
      payload = %{"app_metadata" => %{"consumer_id" => "andrew"}}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: ""
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "returns consumer when scope is in app_metadata", settings do
      payload = %{"app_metadata" => %{"consumer_id" => "andrew", "consumer_scope" => "httpbin:read"}}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: "httpbin:read"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)

      # Scope may be a list
      payload = %{"app_metadata" => %{"consumer_id" => "andrew", "consumer_scope" => ["httpbin:read", "httpbin:write"]}}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: "httpbin:read httpbin:write"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "returns error when token is invalid", settings do
      assert {:error, "JWT token is invalid"} = JWTStrategy.fetch_consumer(:bearer, "invalid token", settings)

      payload = %{"consumer_scope" => "httpbin:read", "consumer_id" => "andrew"}
      other_jwt_token = jwt_token_factory(payload, Base.encode64("not_a_secret"))
      assert {:error, "JWT token is invalid"}
        == JWTStrategy.fetch_consumer(:bearer, other_jwt_token, settings)
    end

    test "returns error when consumer id is not present", settings do
      payload = %{"consumer_scope" => "httpbin:read"}
      jwt_token = jwt_token_factory(payload, settings["secret"])
      assert {:error, "JWT token does not contain Consumer ID"}
        == JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "supports all signing algorithms", settings do
      supported_algorithms = ["HS256", "HS384", "HS512"]

      for algorithm <- supported_algorithms do
        algorithm_atom = algorithm |> String.downcase() |> String.to_atom()
        settings = Map.put(settings, "algorithm", algorithm)

        payload = %{"consumer_scope" => "httpbin:read", "consumer_id" => "andrew"}
        jwt_token = jwt_token_factory(payload, settings["secret"], algorithm_atom)

        assert {:ok, %Consumer{
          id: "andrew",
          metadata: %{"consumer_id" => "andrew", "consumer_scope" => "httpbin:read"},
          scope: "httpbin:read"
        }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
      end
    end
  end

  describe "fetch_consumer/3 with third party resolver" do
    setup do
      mock_conf = Confex.get_env(:annon_api, :acceptance)[:mock]
      mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/"

      {:ok, %{
        "secret" => Base.encode64("a_secret_signature"),
        "third_party_resolver" => true,
        "url_template" => mock_url,
        "algorithm" => "HS256"
      }}
    end

    test "returns token with resolved scopes", settings do
      payload = %{"consumer_id" => "andrew"}
      jwt_token = jwt_token_factory(payload, settings["secret"])
      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/mithril/users/andrew")

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: "api:access"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "ignores scope from token", settings do
      payload = %{"consumer_id" => "andrew", "consumer_scope" => "httpbin:access"}
      jwt_token = jwt_token_factory(payload, settings["secret"])
      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/consumers/andrew")

      assert {:ok, %Consumer{
        id: "andrew",
        metadata: ^payload,
        scope: "api:access"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "ignores third party consumer id", settings do
      payload = %{"consumer_id" => "bob"}
      jwt_token = jwt_token_factory(payload, settings["secret"])
      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/consumers/andrew")

      assert {:ok, %Consumer{
        id: "bob",
        metadata: ^payload,
        scope: "api:access"
      }} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end

    test "returns error with third party resolver message", settings do
      payload = %{"consumer_id" => "bob"}
      jwt_token = jwt_token_factory(payload, settings["secret"])

      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/unathorized")
      assert {:error, "Hi boys!"} = JWTStrategy.fetch_consumer(:bearer, jwt_token, settings)
    end
  end
end
