defmodule Gateway.Plugins.ProxyTest do
  use Gateway.UnitCase

  test "validator correct" do
    model = %APIModel{plugins: [
      %Plugin{is_enabled: true, name: :Proxy, settings: %{"smth" => Poison.encode!(%{})}}
    ]}

    connect = :get
    |> conn("/", Poison.encode!(%{}))
  end

end
