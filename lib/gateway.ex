defmodule Gateway do
  @moduledoc """
  This is an entry point of Gateway application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Gateway.DB.Repo, []),
      http_endpoint_spec(:private_http),
      http_endpoint_spec(:public_http),
      Plug.Adapters.Cowboy.child_spec(:http, Gateway.PrivateRouter, [], private_http_config)
    ]

    opts = [strategy: :one_for_one, name: Gateway.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp endpoint_spec(type) do
    Plug.Adapters.Cowboy.child_spec(:http, Gateway.PublicRouter, [], Confex.get_map(:gateway, type)),
  end
end
