defmodule Annon.Requests.Analytics do
  @moduledoc """
  This module provides base Requests analytic data based on stored data.
  """
  import Ecto.Query, warn: false
  alias Annon.Requests.Repo
  alias Annon.Requests.Request

  def aggregate_latencies(api_ids \\ [], interval) when is_list(api_ids) do
    {interval_seconds, interval_limit} = interval_lexer(interval)

    Request
    |> maybe_filter_by_api_ids(api_ids)
    |> select([request], %{
      api_id: fragment("?->'id'", request.api),
      avg_client_request_latency: avg(fragment("(?->>'client_request')::numeric", request.latencies)),
      avg_gateway_latency: avg(fragment("(?->>'gateway')::numeric", request.latencies)),
      avg_upstream_latency: avg(fragment("(?->>'upstream')::numeric", request.latencies)),
      tick: fragment(~S|(
        date_trunc('seconds', (inserted_at - timestamp 'epoch') / ?) * ? + timestamp 'epoch'
      ) as tick|, ^interval_seconds, ^interval_seconds),
    })
    |> group_by([request], fragment("tick"))
    |> group_by([request], fragment("?->'id'", request.api))
    |> order_by(desc: fragment("tick"))
    |> limit(^interval_limit)
    |> Repo.all()
    |> Enum.map(fn %{tick: tick} = span ->
      Map.put(span, :tick, Ecto.DateTime.cast!(tick))
    end)
  end

  def aggregate_status_codes(api_ids \\ [], interval) when is_list(api_ids) do
    {epoch, limit} = interval_lexer(interval)

    Request
    |> maybe_filter_by_api_ids(api_ids)
    |> select([request], %{
      api_id: fragment("?->'id'", request.api),
      status_code: request.status_code,
      count: count(request.status_code),
      tick: fragment(~S|(
        date_trunc('seconds', (inserted_at - timestamp 'epoch') / ?) * ? + timestamp 'epoch'
      ) as tick|, ^epoch, ^epoch),
    })
    |> group_by([request], fragment("tick"))
    |> group_by([request], fragment("?->'id'", request.api))
    |> group_by([request], request.status_code)
    |> order_by(desc: fragment("tick"))
    |> limit(^limit)
    |> Repo.all()
    |> Enum.map(fn %{tick: tick} = span ->
      Map.put(span, :tick, Ecto.DateTime.cast!(tick))
    end)
  end

  defp maybe_filter_by_api_ids(query, []),
    do: query
  defp maybe_filter_by_api_ids(query, api_ids),
    do: where(query, [request], fragment("?->'id' \\?| ?", request.api, ^api_ids))

  defp interval_lexer(interval) do
    case String.split(interval, " ") do
      [n, min] when min in ["minute", "minutes"] ->
        {n, ""} = Integer.parse(n)
        {n * 60, round(86_400 / n)}
      [n, hour] when hour in ["hour", "hours"] ->
        {n, ""} = Integer.parse(n)
        {n * 3600, round(604_800 / n)}
      [n, day] when day in ["day", "days"] ->
        {n, ""} = Integer.parse(n)
        {n * 86_400, round(2_678_400 / n)}
      _ ->
        {300, 17_280}
    end
  end
end
