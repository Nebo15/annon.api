defmodule Annon.Configuration.MatcherTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Annon.Configuration.Matcher

  setup do
    %{opts: [
      adapter: Annon.CacheTestAdapter,
      cache_space: :mather_config_test,
      test_pid: self()
    ]}
  end

  test "raises when adapter is not set" do
    assert_raise RuntimeError, fn ->
      Matcher.init([test_pid: self()])
    end
  end

  test "initializes adapter", %{opts: opts} do
    {:ok, _} = Matcher.start_link(opts, Annon.Configuration.MatcherTest)
    assert_receive :initialized
  end

  test "uses adapter to match request", %{opts: opts} do
    {:ok, _} = Matcher.start_link(opts, Annon.Configuration.MatcherTest)
    assert {:ok, :i_am_api} =
      Matcher.match_request(Annon.Configuration.MatcherTest, "https", "POST", "example.com", 80, "/my_path")
    assert_receive :match_called
  end

  test "notifies adapter on config change", %{opts: opts} do
    {:ok, _} = Matcher.start_link(opts, Annon.Configuration.MatcherTest)
    assert :ok = Matcher.config_change(Annon.Configuration.MatcherTest)
    assert_receive :config_changed
  end
end
