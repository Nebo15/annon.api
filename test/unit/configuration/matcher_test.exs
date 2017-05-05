defmodule Annon.Configuration.MatcherTest do
  @moduledoc false
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  alias Annon.Configuration.Matcher

  defmodule TestAdapter do
    @moduledoc false
    @behaviour Annon.Configuration.CacheAdapter
    require Logger

    def init do
      Logger.debug("Adapter initialized")
      :ok
    end

    def match_request(_scheme, _method, _host, _port, _path) do
      Logger.debug("Match called")
      {:ok, :i_am_api}
    end

    def config_change do
      Logger.debug("Config changed")
      :ok
    end
  end

  test "raises when adapter is not set" do
    assert_raise RuntimeError, fn ->
      Matcher.init([])
    end
  end

  test "initializes adapter" do
    debug_fn = fn ->
      Matcher.start_link([adapter: Annon.Configuration.CacheAdapter.ETSTest.TestAdapter])
    end

    assert capture_log(debug_fn) =~ "Adapter initialized"
  end

  test "uses adapter to match request" do
    Matcher.start_link([adapter: Annon.Configuration.CacheAdapter.ETSTest.TestAdapter])

    debug_fn = fn ->
      assert {:ok, :i_am_api} = Matcher.match_request("https", "POST", "example.com", 80, "/my_path")
    end

    assert capture_log(debug_fn) =~ "Match called"
  end

  test "notifies adapter on config change" do
    Matcher.start_link([adapter: Annon.Configuration.CacheAdapter.ETSTest.TestAdapter])

    debug_fn = fn ->
      Matcher.config_change()
    end

    assert capture_log(debug_fn) =~ "Config changed"
  end
end
