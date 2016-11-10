defmodule Gateway.Plugins.ProxyTest do
  @moduledoc false
  use Gateway.UnitCase
  alias Gateway.Plugins.Proxy
  import Gateway.Helpers.IP

  @proxy_settings_full %{"host" => "localhost", "path" => "/proxy/test", "port" => 4000, "scheme" => "http"}
  @proxy_settings_port %{"host" => "localhost", "path" => "/proxy/test", "scheme" => "http"}
  @proxy_settings_scheme %{"host" => "localhost", "path" => "/proxy/test", "scheme" => "https"}
  @proxy_settings_path %{"host" => "localhost", "path" => "/proxy", "scheme" => "https"}
  @proxy_settings_just_host %{"host" => "localhost"}

  test "proxy" do
    conn = %Plug.Conn{scheme: :https, port: 6000, request_path: "/some/path", remote_ip: {127, 0, 0, 1}}

    assert Proxy.make_link(@proxy_settings_full, conn) == "http://localhost:4000/proxy/test"
    assert Proxy.make_link(@proxy_settings_port, conn) == "http://localhost/proxy/test"
    assert Proxy.make_link(@proxy_settings_scheme, conn) == "https://localhost/proxy/test"
    assert Proxy.make_link(@proxy_settings_path, conn) == "https://localhost/proxy"
    assert Proxy.make_link(@proxy_settings_just_host, conn) == "https://localhost/some/path"

    headers = [%{"random_name1" => "random_value1"}, %{"random_name2" => "random_value2"}]
    conn = Proxy.add_additional_headers(headers, conn)
    random_value1 = get_req_header(conn, "random_name1")
    random_value2 = get_req_header(conn, "random_name2")
    x_forwarded_for_value = get_req_header(conn, "x-forwarded-for")
    assert ["random_value1"] == random_value1
    assert ["random_value2"] == random_value2
    assert [ip_to_string(conn.remote_ip)] == x_forwarded_for_value
  end

  test "proxying includes query string" do
    conn = %Plug.Conn{request_path: "/some/path", query_string: "key=value"}

    assert Proxy.make_link(@proxy_settings_full, conn) == "http://localhost:4000/proxy/test?key=value"
  end

  test "proxying path 1" do
    incoming_request = make_conn("/mockbin")
    proxy_params = %{"host" => "localhost", "path" => "/mockbin", "strip_request_path" => false}
    assert "https://localhost/mockbin" == Proxy.make_link(proxy_params, incoming_request)
  end

  test "proxying path 2" do
    incoming_request = make_conn("/mockbin/some/path")
    proxy_params = %{"host" => "localhost", "path" => "/mockbin/some/path", "strip_request_path" => false}
    assert "https://localhost/mockbin/some/path" == Proxy.make_link(proxy_params, incoming_request)
  end

  test "proxying path 3" do
    incoming_request = make_conn("/mockbin")
    proxy_params = %{"host" => "localhost", "path" => "/mockbin", "strip_request_path" => true}
    assert "https://localhost" == Proxy.make_link(proxy_params, incoming_request)
  end

  test "proxying path 4" do
    incoming_request = make_conn("/mockbin/some/path")
    proxy_params = %{"host" => "localhost", "path" => "/mockbin", "strip_request_path" => true}
    assert "https://localhost/some/path" == Proxy.make_link(proxy_params, incoming_request)
  end

  defp make_conn(request_path) do
    %Plug.Conn{
      scheme: :https,
      port: 6000,
      request_path: request_path,
      remote_ip: {127, 0, 0, 1}
    }
  end
end
