defmodule Gateway.HTTPTestHelper do
  @moduledoc """
  Gateway HTTP Test Helper
  """

  alias Gateway.DB.Models.Plugin
  alias Gateway.DB.Models.API, as: APIModel

  defmacro __using__(_) do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test
      alias Gateway.DB.Models.Plugin
      alias Gateway.DB.Models.API, as: APIModel
      import Gateway.HTTPTestHelper

      def assert_halt(%Plug.Conn{halted: true} = plug), do: plug
      def assert_not_halt(%Plug.Conn{halted: false} = plug), do: plug

      setup tags do
        :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)

        unless tags[:async] do
          Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Repo, {:shared, self()})
        end

        :ok
      end
    end
  end

  def get_api_model_data do
    api_model = APIModel
    |> EctoFixtures.ecto_fixtures()

    api_model
    |> Map.put(:plugins, [get_plugin_data(api_model.id, "JWT"), get_plugin_data(api_model.id, "Validator")])
  end

  def get_plugin_data(api_id, name \\ "JWT") do
    Plugin
    |> EctoFixtures.ecto_fixtures()
    |> Map.put(:api_id, api_id)
    |> Map.put(:name, name)
  end
end
