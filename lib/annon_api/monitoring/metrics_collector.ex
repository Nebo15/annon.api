defmodule Annon.Monitoring.MetricsCollector do
  @moduledoc """
  This module provides helper functions to persist meaningful metrics to StatsD or DogstatsD servers.

  Code is based on [Statix](https://github.com/lexmag/statix) library.
  """
  import DogStat
  alias Annon.Monitoring.Latencies

  def track_request(_request_id, nil, opts),
    do: increment("request_count", 1, opts)
  def track_request(_request_id, content_length, opts) do
    increment("request_count", 1, opts)
    histogram("request_size", content_length, opts)
  end

  def track_response(_request_id, latencies, opts) do
    %Latencies{client_request: client, upstream: upstream, gateway: gateway} = latencies

    histogram("latencies_client", client, opts)
    histogram("latencies_upstream", upstream, opts)
    histogram("latencies_gateway", gateway, opts)
  end

  def track_repo_activity() do

  end

  def track_latency(name, value, tags) do

  end
end
