defmodule Gateway do
  @moduledoc """
  This is an entry point of Gateway application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    http_config = Confex.get_map(:gateway, :http)

    children = [
      supervisor(Gateway.DB.Repo, []),
      Plug.Adapters.Cowboy.child_spec(:http, Gateway.Router, [], http_config)
    ]

    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
