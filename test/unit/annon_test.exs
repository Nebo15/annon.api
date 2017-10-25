defmodule AnnonTest do
  @moduledoc false
  use ExUnit.Case, async: true

  test "init/2 resolves :system tuples" do
    System.put_env("MY_TEST_ENV", "test_env_value")
    on_exit(fn ->
      System.delete_env("MY_TEST_ENV")
    end)

    assert {:ok, [
      my_conf: "test_env_value",
      other_conf: "persisted"
    ]} == Annon.init(nil, [my_conf: {:system, "MY_TEST_ENV"}, other_conf: "persisted"])
  end

  describe "configure_log_level/1" do
    test "tolerates nil values" do
      assert :ok == Annon.configure_log_level(nil)
    end

    test "raises on invalid LOG_LEVEL" do
      assert_raise ArgumentError, fn ->
        Annon.configure_log_level("super_critical")
      end

      assert_raise ArgumentError, fn ->
        Annon.configure_log_level(:not_a_string)
      end
    end

    test "configures log level" do
      :ok = Annon.configure_log_level("debug")
    end
  end
end
