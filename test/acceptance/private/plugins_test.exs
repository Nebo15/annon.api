defmodule Gateway.Acceptance.Private.PluginsTest do
  use Gateway.AcceptanceCase

  test "invalid JWT Plugin settings" do
    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: false, settings: %{"invalid" => "data"}},
    ])

    "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)

    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: false, settings: %{"invalid" => %{"another" => "map"}}},
    ])

    IO.inspect "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(422)
  end

  test "valid JWT Plugin settings" do
    data = get_api_model_data()
    |> Map.put(:plugins, [
      %{name: "JWT", is_enabled: false, settings: %{"signature" => "string", "invalid" => "data"}},
    ])

     %HTTPoison.Response{body: body} = "apis"
    |> post(Poison.encode!(data), :private)
    |> assert_status(201)

    IO.inspect Poison.decode!(body)

    assert %{"signature" => "string"} == body
    |> Poison.decode!()
    |> get_in(["data", "plugins"])
    |> elem()
  end
end
