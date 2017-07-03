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

    children =
      if Confex.get_env(:annon_api, :enable_ssl?, false),
        do: [http_endpoint_spec(Annon.PublicAPI.Router, :https, :public_https)] ++ children,
      else: children

    opts = [strategy: :one_for_one, name: Annon.PublicAPI.ServerSupervisor]
    supervise(children, opts)
  end

  defp http_endpoint_spec(router, scheme, endpoint) do
    config =
      :annon_api
      |> Confex.get_env(endpoint)
      |> Keyword.put_new(:otp_app, :annon_api)
      |> Keyword.put(:ref, build_ref(router, endpoint))

    Plug.Adapters.Cowboy.child_spec(scheme, router, [], config)
  end

  defp build_ref(plug, scheme) do
    Module.concat(plug, scheme |> to_string() |> String.upcase())
  end
end
