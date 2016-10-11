defmodule Gateway.HTTPTestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test

      setup do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)
      end
    end
  end
end
