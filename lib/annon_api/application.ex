defmodule Annon do
  @moduledoc """
  This is an entry point of Annon application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Configure Logger severity at runtime
    configure_log_level()

    children = [
      supervisor(Annon.Configuration.Repo, []),
      supervisor(Annon.Requests.Repo, []),
      worker(Annon.Configuration.Matcher, [matcher_opts()]),
      http_endpoint_spec(Annon.ManagementAPI.Router, :management_http),
      http_endpoint_spec(Annon.PublicRouter, :public_http),
      http_endpoint_spec(Annon.PrivateRouter, :private_http),
      worker(Annon.AutoClustering, [])
    ]

    opts = [strategy: :one_for_one, name: Annon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp http_endpoint_spec(router, config) do
    Plug.Adapters.Cowboy.child_spec(:http, router, [], Confex.get_map(:annon_api, config))
  end

  defp matcher_opts do
    Application.get_env(:annon_api, :configuration_cache)
  end

  # Loads configuration in `:on_init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def load_from_system_env(config) do
    {:ok, Confex.process_env(config)}
  end

  # Configures Logger level via LOG_LEVEL environment variable.
  defp configure_log_level do
    case System.get_env("LOG_LEVEL") do
      nil ->
        :ok
      level when level in ["debug", "info", "warn", "error"] ->
        Logger.configure(level: String.to_atom(level))
      level ->
        raise ArgumentError, "LOG_LEVEL environment should have one of 'debug', 'info', 'warn', 'error' values," <>
                             "got: #{inspect level}"
    end
  end
end
