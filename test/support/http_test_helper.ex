defmodule Gateway.HTTPTestHelper do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test

      def assert_halt(%Plug.Conn{halted: true} = plug), do: plug
      def assert_not_halt(%Plug.Conn{halted: false} = plug), do: plug

      setup do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)
      end
    end
  end
end
