defmodule Gateway.HTTPTestHelper do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Repo, {:shared, self()})
        end

        :ok
      end
    end
  end
end
