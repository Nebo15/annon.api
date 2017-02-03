defmodule Gateway do
  @moduledoc """
  This is an entry point of Annons application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Gateway.DB.Configs.Repo, []),
      supervisor(Gateway.DB.Logger.Repo, []),
      http_endpoint_spec(Gateway.ManagementRouter, :management_http),
      http_endpoint_spec(Gateway.PublicRouter, :public_http),
      http_endpoint_spec(Gateway.PrivateRouter, :private_http),
      worker(Gateway.AutoClustering, [])
    ]

    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp http_endpoint_spec(router, config) do
    Plug.Adapters.Cowboy.child_spec(:http, router, [], Confex.get_map(:gateway, config))
  end
end
