defmodule Gateway.Acceptance.Private.PluginsTest do
  use Gateway.AcceptanceCase

  test "invalid JWT Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("JWT")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: false, settings: %{"signature" => 1000}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "invalid Validator Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("Validator")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "Validator", is_enabled: false, settings: %{"schema" => "{invalid: schema: json]"}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "invalid ACL Plugin settings" do
    "apis"
    |> post(Poison.encode!(invalid_plugin_data("ACL")), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "ACL", is_enabled: false, settings: %{"scope" => 100}},
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
