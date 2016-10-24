defmodule Gateway.Plugins.ProxyTest do
  use Gateway.UnitCase
  alias Gateway.Plugins.Proxy

  @proxy_settings_full %{"host" => "localhost", "path" => "/proxy/test", "port" => 4000, "scheme" => "http"}
  @proxy_settings_port %{"host" => "localhost", "path" => "/proxy/test", "scheme" => "http"}
  @proxy_settings_scheme %{"host" => "localhost", "path" => "/proxy/test", "scheme" => "https"}
  @proxy_settings_path %{"host" => "localhost", "path" => "/proxy", "scheme" => "https"}

  test "proxy" do
    assert Proxy.make_link(@proxy_settings_full) == "http://localhost:4000/proxy/test"
    assert Proxy.make_link(@proxy_settings_port) == "http://localhost/proxy/test"
    assert Proxy.make_link(@proxy_settings_scheme) == "https://localhost/proxy/test"
    assert Proxy.make_link(@proxy_settings_path) == "https://localhost/proxy"
  end

end
