defmodule Gateway.HTTPTestHelper do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test

      def ins(a) do
        IO.inspect(a)
      end

      def assert_halt(%Plug.Conn{halted: halted} = plug) do
        assert halted === true
        plug
      end

      def assert_not_halt(%Plug.Conn{halted: halted} = plug) do
        assert halted === false
        plug
      end

      setup do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)
      end
    end
  end
end
