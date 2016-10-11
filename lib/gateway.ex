defmodule Gateway do
  @moduledoc """
  This is an entry point of Gateway application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Gateway.DB.Repo, []),
      Plug.Adapters.Cowboy.child_spec(:http, Gateway.HTTPRouter, [], [port: 4000]),
      Plug.Adapters.Cowboy.child_spec(:http, Gateway.AMQPRouter, [], [port: 4001])
    ]

    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
