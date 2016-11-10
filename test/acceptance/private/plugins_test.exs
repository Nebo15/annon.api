defmodule Gateway.Acceptance.Private.PluginsTest do
  @moduledoc false
  use Gateway.AcceptanceCase

  test "invalid JWT Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("jwt")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "jwt", is_enabled: false, settings: %{"signature" => 1000}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "invalid Validator Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("validator")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "validator", is_enabled: false, settings: %{"schema" => "{invalid: schema: json]"}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "invalid ACL Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("acl")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "acl", is_enabled: false, settings: %{"scope" => 100}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "invalid IPRestriction Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("ip_restriction")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "ip_restriction", is_enabled: false, settings: %{"ip_blacklist" => 100, "ip_whitelist" => ["127.0.0.1"]}},
    ])
    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "ip_restriction", is_enabled: false, settings: %{"ip_whitelist" => ["127.0.0.1"]}},
    ])
    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "ip_restriction",
        is_enabled: false,
        settings: %{"ip_blacklist" => ["invalid ip"], "ip_whitelist" => [""]}},
    ])
    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "ip_restriction", is_enabled: false, settings: %{"ip_blacklist" => ["127.0.0.1"],
                                                              "ip_whitelist" => ["127.0.0.256"]}},
    ])
    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "invalid Proxy Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("proxy")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "proxy", is_enabled: false, settings: %{"path" => 100}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  defp invalid_plugin_data(plugin_name) when is_binary(plugin_name) do
    get_api_model_data()
    |> Map.put(:plugins, [
      %{name: plugin_name, is_enabled: false, settings: %{"invalid" => "data"}},
    ])
  end
end
