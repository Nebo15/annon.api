defmodule Gateway do
  @moduledoc """
  This is an entry point of Gateway application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Gateway.DB.Repo, []),
<<<<<<< HEAD
      supervisor(Gateway.Workers.Cassandra, []),
      Plug.Adapters.Cowboy.child_spec(:http, Gateway.Router, [], http_config)
=======
      http_endpoint_spec(Gateway.PrivateRouter, :private_http),
      http_endpoint_spec(Gateway.PublicRouter, :public_http)
>>>>>>> 10ba333d925bfe247e46b81912a3362664cafa21
    ]

    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp http_endpoint_spec(router, config) do
    Plug.Adapters.Cowboy.child_spec(:http, router, [], Confex.get_map(:gateway, config))
  end
end
