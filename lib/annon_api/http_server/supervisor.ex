defmodule Annon.HTTPServer.Supervisor do
  @moduledoc """
  HTTPServer supervisor manages opened HTTP and HTTP ports for API Gateway.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      http_endpoint_spec(Annon.ManagementAPI.Router, :management_http),
      http_endpoint_spec(Annon.PublicRouter, :public_http),
      http_endpoint_spec(Annon.PrivateRouter, :private_http),
    ]

    opts = [strategy: :one_for_one, name: Annon.HTTPServer.Supervisor]
    supervise(children, opts)
  end

  defp http_endpoint_spec(router, config) do
    Plug.Adapters.Cowboy.child_spec(:http, router, [], Confex.get_map(:annon_api, config))
  end
end
