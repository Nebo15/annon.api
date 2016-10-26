defmodule Gateway.Plugins.ProxyTest do
  use Gateway.UnitCase
  alias Gateway.Plugins.Proxy

  @proxy_settings_full %{"host" => "localhost", "path" => "/proxy/test", "port" => 4000, "scheme" => "http"}
  @proxy_settings_port %{"host" => "localhost", "path" => "/proxy/test", "scheme" => "http"}
  @proxy_settings_scheme %{"host" => "localhost", "path" => "/proxy/test", "scheme" => "https"}
  @proxy_settings_path %{"host" => "localhost", "path" => "/proxy", "scheme" => "https"}
  @proxy_settings_just_host %{"host" => "localhost"}

  test "proxy" do
    conn = %Plug.Conn{scheme: :https, port: 6000, request_path: "/some/path"}

    assert Proxy.make_link(@proxy_settings_full, conn) == "http://localhost:4000/proxy/test"
    assert Proxy.make_link(@proxy_settings_port, conn) == "http://localhost/proxy/test"
    assert Proxy.make_link(@proxy_settings_scheme, conn) == "https://localhost/proxy/test"
    assert Proxy.make_link(@proxy_settings_path, conn) == "https://localhost/proxy"
    assert Proxy.make_link(@proxy_settings_just_host, conn) == "https://localhost/some/path"
  end

end
