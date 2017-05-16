defmodule Annon.Monitoring.MetricsCollector do
  @moduledoc """
  This module provides helper functions to persist meaningful metrics to StatsD or DogstatsD servers.
  """
  import DogStat
  alias Annon.Monitoring.Latencies

  def track_request(_request_id, nil, opts),
    do: increment("request.count", 1, opts)
  def track_request(_request_id, content_length, opts) do
    increment("request.count", 1, opts)
    histogram("request.size", content_length, opts)
  end

  def track_response(_request_id, latencies, opts) do
    %Latencies{client_request: client, upstream: upstream, gateway: gateway} = latencies

    increment("responses.count", client, opts)
    histogram("latencies.client", client, opts)
    histogram("latencies.upstream", upstream, opts)
    histogram("latencies.gateway", gateway, opts)
  end
end
