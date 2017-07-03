defmodule Annon.Plugins.Auth.Strategies.OAuthTest do
  @moduledoc false
  use Annon.ConnCase, async: true
  alias Annon.PublicAPI.Consumer
  alias Annon.Plugins.Auth.Strategies.OAuth, as: OAuthStrategy

  describe "fetch_consumer/3" do
    setup do
      mock_conf = Confex.get_env(:annon_api, :acceptance)[:mock]
      mock_url = "http://#{mock_conf[:host]}:#{mock_conf[:port]}/"

      {:ok, %{
        "url_template" => mock_url
      }}
    end

    test "returns token with resolved scopes", settings do
      acces_token = "random_token"
      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/mithril/tokens/" <> acces_token)

      assert {:ok, %Consumer{
        id: "bob",
        metadata: %{},
        scope: "api:access"
      }} = OAuthStrategy.fetch_consumer(:bearer, acces_token, settings)
    end

    test "ignores scope from token", settings do
      acces_token = "random_token"
      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/tokens/random_token")

      assert {:ok, %Consumer{
        id: "bob",
        metadata: %{},
        scope: "api:access"
      }} = OAuthStrategy.fetch_consumer(:bearer, acces_token, settings)
    end

    test "returns error when token is not resolved", settings do
      acces_token = "random_token"

      settings = Map.put(settings, "url_template", "http://httpbin.org/status/200")
      assert {:error, "Invalid access token"} = OAuthStrategy.fetch_consumer(:bearer, acces_token, settings)

      settings = Map.put(settings, "url_template", "http://httpbin.org/ip")
      assert {:error, "Invalid access token"} = OAuthStrategy.fetch_consumer(:bearer, acces_token, settings)
    end

    test "returns error with third party resolver message", settings do
      acces_token = "random_token"

      settings = Map.put(settings, "url_template", settings["url_template"] <> "auth/unathorized")
      assert {:error, "Hi boys!"} = OAuthStrategy.fetch_consumer(:bearer, acces_token, settings)
    end
  end
end
