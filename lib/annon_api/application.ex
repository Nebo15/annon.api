defmodule Annon do
  @moduledoc """
  This is an entry point of Annon application.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Configure Logger severity at runtime
    "LOG_LEVEL"
    |> System.get_env()
    |> configure_log_level()

    children = [
      supervisor(Annon.Configuration.Repo, []),
      supervisor(Annon.Requests.Repo, []),
      worker(DogStat, [metrics_collector_opts()]),
      worker(Annon.Requests.LogWriter, []),
      worker(Annon.Configuration.Matcher, [matcher_opts()]),
      worker(Annon.AutoClustering, []),
      management_endpoint_spec(),
      supervisor(Annon.PublicAPI.ServerSupervisor, []),
    ]

    opts = [strategy: :one_for_one, name: Annon.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def management_endpoint_spec do
    config = Confex.get_map(:annon_api, :management_http)
    Plug.Adapters.Cowboy.child_spec(:http, Annon.ManagementAPI.Router, [], config)
  end

  defp matcher_opts do
    Application.get_env(:annon_api, :configuration_cache)
  end

  defp metrics_collector_opts do
    Confex.get_map(:annon_api, :metrics_collector)
  end

  # Loads configuration in `:on_init` callbacks and replaces `{:system, ..}` tuples via Confex
  @doc false
  def load_from_system_env(config) do
    {:ok, Confex.process_env(config)}
  end

  # Configures Logger level via LOG_LEVEL environment variable.
  def configure_log_level(nil),
    do: :ok
  def configure_log_level(level) when level in ["debug", "info", "warn", "error"],
    do: Logger.configure(level: String.to_atom(level))
  def configure_log_level(level),
    do: raise ArgumentError, "LOG_LEVEL environment should have one of 'debug', 'info', 'warn', 'error' values," <>
                             "got: #{inspect level}"
end
