defmodule Gateway.UnitCase do
  @moduledoc """
  Gateway HTTP Test Helper
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use ExUnit.Case, async: true
      use Plug.Test
      alias Gateway.DB.Models.Plugin
      alias Gateway.DB.Models.API, as: APIModel
      alias Gateway.DB.Models.Log
      import Gateway.UnitCase
      import Gateway.Fixtures
    end
  end

  def assert_halt(%Plug.Conn{halted: true} = plug), do: plug
  def assert_not_halt(%Plug.Conn{halted: false} = plug), do: plug

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Gateway.DB.Logger.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(Gateway.DB.Logger.Repo, {:shared, self()})
    end

    :ets.delete_all_objects(:config)

    :ok
  end
end
