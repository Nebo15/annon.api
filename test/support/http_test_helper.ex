defmodule Gateway.HTTPTestHelper do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test
      alias Gateway.DB.Models.Plugin
      alias Gateway.DB.Models.API, as: APIModel

      def get_api_model_data do
        api_model = APIModel
        |> EctoFixtures.ecto_fixtures()

        api_model
        |> Map.put(:plugins, [get_plugin_data(api_model.id), get_plugin_data(api_model.id)])
      end

      def get_plugin_data(api_id) do
        Plugin
        |> EctoFixtures.ecto_fixtures()
        |> Map.put(:api_id, api_id)
      end

      def assert_halt(%Plug.Conn{halted: true} = plug), do: plug
      def assert_not_halt(%Plug.Conn{halted: false} = plug), do: plug

      setup do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)
      end
    end
  end
end
