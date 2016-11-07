defmodule Gateway.Plugins.ProxyTest do
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

    headers = [%{"random_name1" => "random_value1"}, %{"random_name2" => "random_value2"}]
    conn = Proxy.add_additional_headers(headers, conn)
    random_value1 = get_req_header(conn, "random_name1")
    random_value2 = get_req_header(conn, "random_name2")
    x_forwarded_for_value = get_req_header(conn, "x-forwarded-for")
    assert ["random_value1"] == random_value1
    assert ["random_value2"] == random_value2
    assert [ip_to_string(conn.remote_ip)] == x_forwarded_for_value
  end

  test "proxying path 1" do
    conn = make_conn("/mockbin", false)
    assert Proxy.make_link(@proxy_settings_just_host, conn) == "https://localhost/mockbin"
  end

  test "proxying path 2" do
    conn = make_conn("/mockbin/some/path", false)
    assert Proxy.make_link(@proxy_settings_just_host, conn) == "https://localhost/mockbin/some/path"
  end

  test "proxying path 3" do
    conn = make_conn("/mockbin", true)
    assert Proxy.make_link(@proxy_settings_just_host, conn) == "https://localhost"
  end

  test "proxying path 4" do
    conn = make_conn("/mockbin/some/path", true)
    assert Proxy.make_link(@proxy_settings_just_host, conn) == "https://localhost/some/path"
  end

  defp make_conn(request_path, strip_request_path) do
    %Plug.Conn{
      scheme: :https,
      port: 6000,
      request_path: request_path,
      remote_ip: {127, 0, 0, 1},
      private: %{
        api_config: %{
          strip_request_path: strip_request_path,
          request: %{ path: "/mockbin" }
        }
      }
    }
  end
end
