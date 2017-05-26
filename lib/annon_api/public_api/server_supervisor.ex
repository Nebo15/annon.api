defmodule Annon.PublicAPI.ServerSupervisor do
  @moduledoc """
  PublicAPI supervisor manages opened HTTP and HTTP ports for API Gateway.
  """
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init(_) do
    children = [
      http_endpoint_spec(Annon.PublicAPI.Router, :http, :public_http),
      http_endpoint_spec(Annon.PublicAPI.Router, :http, :private_http),
    ]

    opts = [strategy: :one_for_one, name: Annon.PublicAPI.ServerSupervisor]
    supervise(children, opts)
  end

  def http_endpoint_spec(router, scheme, endpoint) do
    config =
      :annon_api
      |> Confex.get_map(endpoint)
      |> Keyword.put(:ref, build_ref(router, endpoint))

    Plug.Adapters.Cowboy.child_spec(scheme, router, [], config)
  end

  defp build_ref(plug, scheme) do
    Module.concat(plug, scheme |> to_string() |> String.upcase())
  end
end
