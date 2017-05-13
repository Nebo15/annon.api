defmodule Annon.Requests.Analytics do
  @moduledoc """
  This module provides base Requests analytic data based on stored data.
  """
  import Ecto.Query, warn: false
  alias Annon.Requests.Repo
  alias Annon.Requests.Request

  def aggregate_latencies(api_ids, interval) when is_list(api_ids) do
    {epoch, limit} = by(interval)

    Request
    |> where([request], fragment("?->'id' \\?| ?", request.api, ^api_ids))
    |> select([request], %{
      api_id: fragment("?->'id'", request.api),
      avg_client_request_latency: avg(fragment("(?->>'client_request')::numeric", request.latencies)),
      avg_gateway_latency: avg(fragment("(?->>'gateway')::numeric", request.latencies)),
      avg_upstream_latency: avg(fragment("(?->>'upstream')::numeric", request.latencies)),
      tick: fragment(~S|(
        date_trunc('seconds', (inserted_at - timestamptz 'epoch') / ?) * ? + timestamptz 'epoch'
      ) as tick|, ^epoch, ^epoch),
    })
    |> group_by([request], fragment("tick"))
    |> group_by([request], fragment("?->'id'", request.api))
    |> order_by(desc: fragment("tick"))
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(fn %{tick: tick} = span ->
      Map.put(span, :tick, Ecto.DateTime.cast!(tick))
    end)
  end

  defp by({n, :minutes}),
    do: {n * 60, 288}
  defp by({n, :hours}),
    do: {n * 60, 288}
  defp by({n, :days}),
    do: {n * 60, 288}
end
