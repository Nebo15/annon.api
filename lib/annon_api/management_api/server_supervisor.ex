defmodule Annon.ManagementAPI.ServerSupervisor do
  @moduledoc """
  This supervisor manages endpoints for management API.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    config = Confex.get_env(:annon_api, :management_http)

    children = [
      {Plug.Adapters.Cowboy2, scheme: :http, plug: Annon.ManagementAPI.Router, options: config}
    ]

    opts = [strategy: :one_for_one, name: Annon.ManagementAPI.ServerSupervisor]

    Supervisor.init(children, opts)
  end
end
