defmodule Annon.Plugins.Proxy.UpstreamRequestTest do
  @moduledoc false
  use Annon.UnitCase, async: true
  import Annon.Plugins.Proxy.UpstreamRequest
  alias Annon.Plugins.Proxy.UpstreamRequest

  describe "to_upstream_url/1" do
    test "constructs valid url" do
      assert "http://example.com:80/subpath?a=b#hello" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "http",
          host: "example.com",
          port: 80,
          path: "/subpath",
          query_params: %{"a" => "b"},
          fragment: "hello"
        })

      assert "https://example.com:123/subpath" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "https",
          host: "example.com",
          port: 123,
          path: "/subpath",
          query_params: nil,
          fragment: nil
        })

      assert "https://example.com:123/subpath" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "https",
          host: "example.com",
          port: 123,
          path: "subpath",
          query_params: nil,
          fragment: nil
        })

      assert "http://example.com:80/" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "http",
          host: "example.com",
          port: nil,
          path: nil,
          query_params: nil,
          fragment: nil
        })
    end

    test "raises is scheme is not set" do
      assert_raise RuntimeError, "Upstream request scheme is not set.", fn ->
        to_upstream_url!(%UpstreamRequest{
          scheme: nil,
          host: "example.com",
          port: nil,
          path: nil,
          query_params: nil,
          fragment: nil
        })
      end
    end

    test "raises is host is not set" do
      assert_raise RuntimeError, "Upstream request host is not set.", fn ->
        to_upstream_url!(%UpstreamRequest{
          scheme: "http",
          host: nil,
          port: nil,
          path: nil,
          query_params: nil,
          fragment: nil
        })
      end
    end

    test "overrides port" do
      assert "http://example.com:8080/subpath?a=b#hello" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "http",
          host: "example.com",
          port: 8080,
          path: "/subpath",
          query_params: %{"a" => "b"},
          fragment: "hello"
        })
    end

    test "accepts port as a string" do
      assert "http://example.com:8080/subpath?a=b#hello" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "http",
          host: "example.com",
          port: "8080",
          path: "/subpath",
          query_params: %{"a" => "b"},
          fragment: "hello"
        })
    end

    test "resolves default port" do
      assert "https://example.com:443/subpath?a=b#hello" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "https",
          host: "example.com",
          port: nil,
          path: "/subpath",
          query_params: %{"a" => "b"},
          fragment: "hello"
        })
    end

    test "accepts query params as string" do
      assert "https://example.com:443/subpath?a=b#hello" ==
        to_upstream_url!(%UpstreamRequest{
          scheme: "https",
          host: "example.com",
          port: nil,
          path: "/subpath",
          query_params: "a=b",
          fragment: "hello"
        })
    end
  end

  test "get_upstream_path/4" do
    # This should always cover all cases from docs: http://docs.annon.apiary.io/#reference/plugins/proxy
    assert "/proxy/api"     == get_upstream_path("/api",     "/proxy", "/api",  false)
    assert "/proxy/api/foo" == get_upstream_path("/api/foo", "/proxy", "/api",  false)
    assert "/api"           == get_upstream_path("/api",     "/",      "/api",  false)
    assert "/api/foo"       == get_upstream_path("/api/foo", "/",      "/api",  false)


    assert "/proxy"         == get_upstream_path("/api",     "/proxy", "/api",  true)
    assert "/proxy/foo"     == get_upstream_path("/api/foo", "/proxy", "/api",  true)
    assert "/"              == get_upstream_path("/api",     "/",      "/api",  true)
    assert "/foo"           == get_upstream_path("/api/foo", "/",      "/api",  true)

    # Trailing slash cases
    assert "/proxy/api/"    == get_upstream_path("/api/",    "/proxy", "/api",  false)
    assert "/api/"          == get_upstream_path("/api/",    "/",      "/api",  false)
    assert "/proxy/"        == get_upstream_path("/api/",    "/proxy", "/api",  true)
    assert "/"              == get_upstream_path("/api/",    "/",      "/api/", true)

    # Subpaths cases
    assert "/proxy/api/blog" == get_upstream_path("/api/blog", "/proxy", "/api",  false)
    assert "/api/blog/" == get_upstream_path("/api/blog/", "/", "/api",  false)
    assert "/proxy/blog" == get_upstream_path("/api/blog", "/proxy", "/api",  true)
    assert "/blog" == get_upstream_path("/api/blog", "/", "/api/", true)

    # Other edge cases
    assert "/foo/api" == get_upstream_path("/api/foo/api", "/", "/api",  true)
    assert "/foo/api" == get_upstream_path("/api/foo/api", "/", "/api",  true)
  end
end
