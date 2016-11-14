defmodule Gateway.Plugins.ProxyTest do
  @moduledoc false
  use Gateway.UnitCase, async: true
  alias Gateway.Plugins.Proxy
  import Gateway.Helpers.IP

  @api_path "/my_api"

  describe "proxy link builder" do
    setup do
      %{conn: make_conn("/some/path")}
    end

    test "supports port", %{conn: conn} do
      assert Proxy.make_link(%{
        "host" => "localhost",
        "path" => "/proxy/test",
        "scheme" => "http"
      }, @api_path, conn) == "http://localhost/proxy/test/some/path"
    end

    test "supports scheme", %{conn: conn} do
      assert Proxy.make_link(%{
        "host" => "localhost",
        "path" => "/proxy/test",
        "scheme" => "https"
      }, @api_path, conn) == "https://localhost/proxy/test/some/path"
    end

    test "supports path", %{conn: conn} do
      assert Proxy.make_link(%{
        "host" => "localhost",
        "path" => "/proxy",
        "scheme" => "https"
      }, @api_path, conn) == "https://localhost/proxy/some/path"
    end

    test "works when only host is set", %{conn: conn} do
      assert Proxy.make_link(%{"host" => "localhost"}, @api_path, conn) == "https://localhost/some/path"
    end

    test "works with all settings", %{conn: conn} do
      assert Proxy.make_link(%{
        "host" => "localhost",
        "path" => "/proxy/test",
        "port" => 4000,
        "scheme" => "http"
      }, @api_path, conn) == "http://localhost:4000/proxy/test/some/path"
    end

    test "puts additional headers", %{conn: conn} do
      headers = [%{"random_name1" => "random_value1"}, %{"random_name2" => "random_value2"}]
      conn = Proxy.add_additional_headers(headers, conn)
      random_value1 = get_req_header(conn, "random_name1")
      random_value2 = get_req_header(conn, "random_name2")
      x_forwarded_for_value = get_req_header(conn, "x-forwarded-for")
      assert ["random_value1"] == random_value1
      assert ["random_value2"] == random_value2
      assert [ip_to_string(conn.remote_ip)] == x_forwarded_for_value
    end

    test "preserves query string" do
      conn = %Plug.Conn{request_path: "/some/path", query_string: "key=value"}
      assert Proxy.make_link(%{
        "host" => "localhost",
        "path" => "/proxy/test",
        "port" => 4000,
        "scheme" => "http"
      }, @api_path, conn) == "http://localhost:4000/proxy/test/some/path?key=value"
    end

    test "preserves request path" do
      incoming_request = make_conn("/mockbin")
      proxy_params = %{"host" => "localhost", "path" => "/proxy", "strip_request_path" => false}
      assert "https://localhost/proxy/mockbin" == Proxy.make_link(proxy_params, @api_path, incoming_request)
    end

    test "preserves deep request paths" do
      incoming_request = make_conn("/mockbin/some/path")
      proxy_params = %{"host" => "localhost", "path" => "/", "strip_request_path" => false}
      assert "https://localhost/mockbin/some/path" == Proxy.make_link(proxy_params, @api_path, incoming_request)
    end

    test "strips request path" do
      incoming_request = make_conn("#{@api_path}/foo")
      proxy_params = %{"host" => "localhost", "path" => "/mockbin", "strip_request_path" => true}
      assert "https://localhost/mockbin/foo" == Proxy.make_link(proxy_params, @api_path, incoming_request)
    end

    test "strips deep requests paths" do
      incoming_request = make_conn("#{@api_path}/some/path")
      proxy_params = %{"host" => "localhost", "path" => "/mockbin", "strip_request_path" => true}
      assert "https://localhost/mockbin/some/path" == Proxy.make_link(proxy_params, @api_path, incoming_request)
    end
  end

  describe "Proxying headers headers" do
    test "selected headers are not forwarded to upstream" do
      plugin_settings = %{
        "headers_to_strip" => [
          "authorization",
          "some-other-header",
        ],
        "strip_headers" => true
      }

      conn =
        make_conn("/")
        |> Plug.Conn.put_req_header("should", "remain")
        |> Plug.Conn.put_req_header("authorization", "secret")
        |> Plug.Conn.put_req_header("some-other-header", "another-secret")

      headers_after_filter =
        conn
        |> Gateway.Plugins.Proxy.skip_filtered_headers(plugin_settings)
        |> IO.inspect
        |> Map.get(:req_headers)

      assert [{"should", "remain"}] == headers_after_filter
    end
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
